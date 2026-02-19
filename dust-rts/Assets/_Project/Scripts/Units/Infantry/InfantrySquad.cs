using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Units.Core;
using DustRTS.Combat.Cover;
using DustRTS.Territory;

namespace DustRTS.Units.Infantry
{
    /// <summary>
    /// Infantry squad - operates as a group, can capture points and garrison.
    /// </summary>
    public class InfantrySquad : Unit
    {
        [Header("Squad")]
        [SerializeField] private int maxSquadSize = 4;
        [SerializeField] private SquadMember memberPrefab;
        [SerializeField] private SquadFormation formation;

        [Header("Cover")]
        [SerializeField] private LayerMask coverLayer;
        [SerializeField] private float coverSearchRadius = 5f;

        [Header("Suppression")]
        [SerializeField] private float suppressionDecayRate = 0.2f;

        private List<SquadMember> members = new();
        private CoverState currentCover = CoverState.None;
        private float suppressionLevel;
        private bool isGarrisoned;
        private GarrisonPoint currentGarrison;
        private CapturePoint targetCapturePoint;

        public int CurrentSize => members.Count(m => m != null && m.IsAlive);
        public int MaxSize => maxSquadSize;
        public bool IsWiped => CurrentSize == 0;
        public CoverState CurrentCover => currentCover;
        public float SuppressionLevel => suppressionLevel;
        public bool IsSuppressed => suppressionLevel > 0.5f;
        public bool IsPinned => suppressionLevel > 0.8f;
        public bool IsGarrisoned => isGarrisoned;

        protected override void Awake()
        {
            base.Awake();

            if (formation == null)
            {
                formation = gameObject.AddComponent<SquadFormation>();
            }
        }

        public override void Initialize(Team team)
        {
            base.Initialize(team);
            SpawnSquadMembers();
        }

        private void SpawnSquadMembers()
        {
            if (memberPrefab == null)
            {
                Debug.LogWarning($"[InfantrySquad] {name} has no member prefab assigned");
                return;
            }

            for (int i = 0; i < maxSquadSize; i++)
            {
                var member = Instantiate(memberPrefab, transform);
                member.Initialize(this, i);
                members.Add(member);
            }
        }

        protected override void Update()
        {
            if (!IsAlive) return;

            base.Update();

            UpdateFormation();
            UpdateCover();
            UpdateSuppression();
        }

        private void UpdateFormation()
        {
            if (isGarrisoned) return;

            var positions = formation.GetPositions(
                transform.position,
                transform.forward,
                CurrentSize
            );

            int posIndex = 0;
            for (int i = 0; i < members.Count && posIndex < positions.Length; i++)
            {
                if (members[i] != null && members[i].IsAlive)
                {
                    members[i].SetTargetPosition(positions[posIndex]);
                    posIndex++;
                }
            }
        }

        private void UpdateCover()
        {
            if (isGarrisoned)
            {
                currentCover = CoverState.Garrison;
                return;
            }

            // Simple cover check - find nearby cover points
            var coverPoints = Physics.OverlapSphere(transform.position, coverSearchRadius, coverLayer);

            if (coverPoints.Length > 0)
            {
                // Determine cover quality based on threat direction
                Vector3 threatDir = Vector3.zero;
                if (currentTarget != null)
                {
                    threatDir = (currentTarget.transform.position - transform.position).normalized;
                }

                currentCover = EvaluateCover(coverPoints, threatDir);
            }
            else
            {
                currentCover = CoverState.None;
            }
        }

        private CoverState EvaluateCover(Collider[] coverPoints, Vector3 threatDirection)
        {
            // Simple evaluation - check if any cover point is between us and threat
            foreach (var col in coverPoints)
            {
                var coverPoint = col.GetComponent<CoverPoint>();
                if (coverPoint == null) continue;

                Vector3 toCover = (coverPoint.transform.position - transform.position).normalized;

                // If cover is roughly in the direction of the threat
                if (Vector3.Dot(toCover, threatDirection) > 0.3f)
                {
                    return coverPoint.CoverType == CoverType.Heavy
                        ? CoverState.Heavy
                        : CoverState.Light;
                }
            }

            return CoverState.None;
        }

        private void UpdateSuppression()
        {
            // Decay suppression over time
            suppressionLevel -= suppressionDecayRate * Time.deltaTime;
            suppressionLevel = Mathf.Clamp01(suppressionLevel);

            // Apply suppression effects
            if (IsPinned)
            {
                // Pinned - can't move
                if (movement.IsMoving)
                {
                    movement.Stop();
                }
            }
            else if (IsSuppressed)
            {
                // Suppressed - move slower
                movement.SetSpeedMultiplier(0.5f);
            }
            else
            {
                movement.ResetSpeed();
            }
        }

        public void ApplySuppression(float amount)
        {
            float resistance = unitData.suppressionResistance;
            amount *= (1f - resistance);
            suppressionLevel += amount;
            suppressionLevel = Mathf.Clamp01(suppressionLevel);
        }

        public float GetDamageReduction()
        {
            return currentCover switch
            {
                CoverState.Garrison => 0.75f,
                CoverState.Heavy => 0.5f,
                CoverState.Light => 0.25f,
                _ => 0f
            };
        }

        // Override movement to leave garrison
        public override void MoveTo(Vector3 position, bool queue = false)
        {
            if (isGarrisoned)
            {
                ExitGarrison();
            }

            // Clear capture target
            targetCapturePoint = null;

            base.MoveTo(position, queue);
        }

        // Capturing
        public override void Capture(CapturePoint point, bool queue = false)
        {
            if (!unitData.canCapture)
            {
                Debug.LogWarning($"[InfantrySquad] {name} cannot capture");
                return;
            }

            targetCapturePoint = point;
            base.Capture(point, queue);
        }

        protected override void UpdateCapturingState()
        {
            if (targetCapturePoint == null)
            {
                SetState(UnitState.Idle);
                return;
            }

            float distance = Vector3.Distance(transform.position, targetCapturePoint.transform.position);

            if (distance > targetCapturePoint.CaptureRadius * 0.8f)
            {
                // Move to capture point
                movement.SetDestination(targetCapturePoint.transform.position);
            }
            else
            {
                // In range - stop and wait for capture
                movement.Stop();

                // Check if captured
                if (targetCapturePoint.IsOwnedBy(team))
                {
                    targetCapturePoint = null;
                    SetState(UnitState.Idle);
                }
            }
        }

        // Garrison
        public void EnterGarrison(GarrisonPoint garrison)
        {
            if (!unitData.canGarrison) return;
            if (garrison == null || garrison.IsFull) return;

            isGarrisoned = true;
            currentGarrison = garrison;
            garrison.AddOccupant(this);

            // Hide squad members
            foreach (var member in members)
            {
                if (member != null)
                {
                    member.SetVisible(false);
                }
            }

            movement.DisableAgent();
            SetState(UnitState.Garrisoned);
        }

        public void ExitGarrison()
        {
            if (!isGarrisoned) return;

            if (currentGarrison != null)
            {
                currentGarrison.RemoveOccupant(this);
                transform.position = currentGarrison.ExitPoint.position;
            }

            isGarrisoned = false;
            currentGarrison = null;

            // Show squad members
            foreach (var member in members)
            {
                if (member != null)
                {
                    member.SetVisible(true);
                }
            }

            movement.EnableAgent();
            SetState(UnitState.Idle);
        }

        // Casualties
        public void TakeCasualty(SquadMember member)
        {
            member.Kill();

            // Morale hit
            ApplySuppression(0.2f);

            if (IsWiped)
            {
                health.Kill();
            }
        }

        protected override void HandleDeath()
        {
            // Kill all remaining members
            foreach (var member in members)
            {
                if (member != null && member.IsAlive)
                {
                    member.Kill();
                }
            }

            if (isGarrisoned)
            {
                ExitGarrison();
            }

            base.HandleDeath();
        }

        public List<SquadMember> GetAliveMembers()
        {
            return members.Where(m => m != null && m.IsAlive).ToList();
        }
    }

    public enum CoverState
    {
        None,
        Light,
        Heavy,
        Garrison
    }
}
