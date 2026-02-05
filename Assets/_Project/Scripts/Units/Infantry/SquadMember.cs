using UnityEngine;

namespace DustRTS.Units.Infantry
{
    /// <summary>
    /// Individual soldier within a squad.
    /// Handles individual movement, health, and visuals.
    /// </summary>
    public class SquadMember : MonoBehaviour
    {
        [Header("Movement")]
        [SerializeField] private float moveSpeed = 5f;
        [SerializeField] private float rotationSpeed = 360f;
        [SerializeField] private float formationTolerance = 0.5f;

        [Header("Health")]
        [SerializeField] private int maxHealth = 25;
        [SerializeField] private int currentHealth;

        [Header("Visuals")]
        [SerializeField] private GameObject visualRoot;
        [SerializeField] private Renderer[] renderers;

        private InfantrySquad squad;
        private int memberIndex;
        private Vector3 targetPosition;
        private bool isAlive = true;

        public InfantrySquad Squad => squad;
        public int MemberIndex => memberIndex;
        public bool IsAlive => isAlive;
        public int Health => currentHealth;

        public void Initialize(InfantrySquad squad, int index)
        {
            this.squad = squad;
            memberIndex = index;
            currentHealth = maxHealth;
            isAlive = true;
            targetPosition = transform.position;
        }

        private void Update()
        {
            if (!isAlive) return;

            MoveToFormationPosition();
        }

        private void MoveToFormationPosition()
        {
            Vector3 toTarget = targetPosition - transform.position;
            toTarget.y = 0;

            float distance = toTarget.magnitude;

            if (distance > formationTolerance)
            {
                // Move toward target
                Vector3 moveDir = toTarget.normalized;
                transform.position += moveDir * moveSpeed * Time.deltaTime;

                // Rotate toward movement direction
                if (moveDir.sqrMagnitude > 0.001f)
                {
                    Quaternion targetRot = Quaternion.LookRotation(moveDir);
                    transform.rotation = Quaternion.RotateTowards(
                        transform.rotation,
                        targetRot,
                        rotationSpeed * Time.deltaTime
                    );
                }
            }
            else
            {
                // Face same direction as squad
                transform.rotation = Quaternion.RotateTowards(
                    transform.rotation,
                    squad.transform.rotation,
                    rotationSpeed * Time.deltaTime
                );
            }
        }

        public void SetTargetPosition(Vector3 position)
        {
            targetPosition = position;
        }

        public void TakeDamage(int amount)
        {
            if (!isAlive) return;

            currentHealth -= amount;

            if (currentHealth <= 0)
            {
                squad.TakeCasualty(this);
            }
        }

        public void Kill()
        {
            if (!isAlive) return;

            isAlive = false;
            currentHealth = 0;

            // Play death animation/effects
            SetVisible(false);

            // Could spawn ragdoll or death effect here
        }

        public void SetVisible(bool visible)
        {
            if (visualRoot != null)
            {
                visualRoot.SetActive(visible);
            }
            else
            {
                foreach (var rend in renderers)
                {
                    if (rend != null)
                    {
                        rend.enabled = visible;
                    }
                }
            }
        }

        public void SetColor(Color color)
        {
            foreach (var rend in renderers)
            {
                if (rend != null)
                {
                    var props = new MaterialPropertyBlock();
                    props.SetColor("_Color", color);
                    rend.SetPropertyBlock(props);
                }
            }
        }
    }
}
