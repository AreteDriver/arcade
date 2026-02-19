using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Units.Core;

namespace DustRTS.Territory
{
    /// <summary>
    /// A point that can be captured by infantry to control a sector.
    /// </summary>
    public class CapturePoint : MonoBehaviour
    {
        [Header("Capture Settings")]
        [SerializeField] private float captureTime = 30f;
        [SerializeField] private float captureRadius = 10f;
        [SerializeField] private LayerMask captureLayer;
        [SerializeField] private int maxCaptureSpeed = 3;

        [Header("Initial State")]
        [SerializeField] private bool startsNeutral = true;

        [Header("Visuals")]
        [SerializeField] private MeshRenderer flagRenderer;
        [SerializeField] private Transform progressIndicator;
        [SerializeField] private Color neutralColor = Color.gray;

        // State
        private float captureProgress;
        private Team capturingTeam;
        private Team owningTeam;
        private bool isContested;

        public float Progress => captureProgress;
        public Team OwningTeam => owningTeam;
        public Team CapturingTeam => capturingTeam;
        public bool IsNeutral => owningTeam == null;
        public bool IsContested => isContested;
        public float CaptureRadius => captureRadius;

        public event Action<Team> OnCaptured;
        public event Action<Team, float> OnCaptureProgress;
        public event Action OnContested;
        public event Action OnContestedEnded;

        private void Start()
        {
            if (startsNeutral)
            {
                owningTeam = null;
            }
            UpdateVisuals();
        }

        private void Update()
        {
            UpdateCapture();
            UpdateVisuals();
        }

        private void UpdateCapture()
        {
            // Count units in capture zone
            var colliders = Physics.OverlapSphere(transform.position, captureRadius, captureLayer);

            Dictionary<Team, int> teamCounts = new();

            foreach (var col in colliders)
            {
                var unit = col.GetComponentInParent<Unit>();
                if (unit == null || !unit.IsAlive) continue;
                if (!unit.Data.canCapture) continue;

                var team = unit.Team;
                if (team == null || team.IsNeutral) continue;

                if (!teamCounts.ContainsKey(team))
                    teamCounts[team] = 0;
                teamCounts[team]++;
            }

            // Determine capture state
            bool wasContested = isContested;

            if (teamCounts.Count == 0)
            {
                // No one here - progress decays
                isContested = false;
                DecayProgress();
            }
            else if (teamCounts.Count == 1)
            {
                // One team present
                var team = teamCounts.Keys.First();
                int unitCount = teamCounts[team];
                isContested = false;

                if (team == owningTeam)
                {
                    // Owner reinforcing - reset enemy progress
                    DecayProgress();
                }
                else
                {
                    // Enemy capturing
                    ProcessCapture(team, unitCount);
                }
            }
            else
            {
                // Multiple teams - contested
                isContested = true;
            }

            // Fire contested events
            if (isContested && !wasContested)
            {
                OnContested?.Invoke();
            }
            else if (!isContested && wasContested)
            {
                OnContestedEnded?.Invoke();
            }
        }

        private void ProcessCapture(Team team, int unitCount)
        {
            // If different team is capturing, need to decap first
            if (capturingTeam != null && capturingTeam != team)
            {
                DecayProgress();
                if (captureProgress <= 0)
                {
                    capturingTeam = team;
                }
                return;
            }

            capturingTeam = team;

            // Progress scales with unit count (capped)
            int speedMultiplier = Mathf.Min(unitCount, maxCaptureSpeed);
            float progressRate = (1f / captureTime) * speedMultiplier;

            captureProgress += progressRate * Time.deltaTime;
            OnCaptureProgress?.Invoke(team, captureProgress);

            if (captureProgress >= 1f)
            {
                CompleteCapture(team);
            }
        }

        private void DecayProgress()
        {
            if (captureProgress <= 0) return;

            float decayRate = 0.5f / captureTime; // Decay at half speed
            captureProgress -= decayRate * Time.deltaTime;
            captureProgress = Mathf.Max(0f, captureProgress);

            if (captureProgress <= 0)
            {
                capturingTeam = null;
            }
        }

        private void CompleteCapture(Team newOwner)
        {
            var previousOwner = owningTeam;
            owningTeam = newOwner;
            captureProgress = 0f;
            capturingTeam = null;

            Debug.Log($"[CapturePoint] {name} captured by {newOwner.TeamName}");
            OnCaptured?.Invoke(newOwner);
        }

        public void SetOwner(Team team)
        {
            owningTeam = team;
            captureProgress = 0f;
            capturingTeam = null;
            UpdateVisuals();
        }

        private void UpdateVisuals()
        {
            if (flagRenderer != null)
            {
                Color color = owningTeam != null ? owningTeam.FactionColor : neutralColor;

                // Blend with capturing team color if being captured
                if (capturingTeam != null && captureProgress > 0)
                {
                    color = Color.Lerp(color, capturingTeam.FactionColor, captureProgress);
                }

                flagRenderer.material.color = color;
            }

            if (progressIndicator != null)
            {
                progressIndicator.localScale = new Vector3(captureProgress, 1f, 1f);
            }
        }

        public bool IsOwnedBy(Team team)
        {
            return owningTeam == team;
        }

        public bool IsBeingCapturedBy(Team team)
        {
            return capturingTeam == team && captureProgress > 0;
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0f, 1f, 0f, 0.3f);
            Gizmos.DrawWireSphere(transform.position, captureRadius);
        }
    }
}
