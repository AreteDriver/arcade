using UnityEngine;

namespace DustRTS.Combat.Cover
{
    /// <summary>
    /// A point that provides cover for infantry.
    /// </summary>
    public class CoverPoint : MonoBehaviour
    {
        [Header("Cover")]
        [SerializeField] private CoverType coverType = CoverType.Light;
        [SerializeField] private float coverRadius = 2f;
        [SerializeField] private Vector3 coverDirection = Vector3.forward;

        [Header("Capacity")]
        [SerializeField] private int maxOccupants = 2;
        private int currentOccupants;

        public CoverType CoverType => coverType;
        public float CoverRadius => coverRadius;
        public Vector3 CoverDirection => transform.TransformDirection(coverDirection);
        public bool IsAvailable => currentOccupants < maxOccupants;
        public int RemainingCapacity => maxOccupants - currentOccupants;

        public float GetDamageReduction()
        {
            return coverType switch
            {
                CoverType.Heavy => 0.5f,
                CoverType.Light => 0.25f,
                _ => 0f
            };
        }

        public bool ProvidesCoverFrom(Vector3 threatDirection)
        {
            // Cover is effective if threat is coming from in front of cover
            float dot = Vector3.Dot(CoverDirection, threatDirection.normalized);
            return dot > 0.3f;
        }

        public void Occupy()
        {
            currentOccupants++;
        }

        public void Vacate()
        {
            currentOccupants = Mathf.Max(0, currentOccupants - 1);
        }

        private void OnDrawGizmos()
        {
            Gizmos.color = coverType == CoverType.Heavy ? Color.blue : Color.cyan;
            Gizmos.DrawWireSphere(transform.position, coverRadius);

            // Draw cover direction
            Gizmos.color = Color.red;
            Gizmos.DrawRay(transform.position, CoverDirection * 2f);
        }
    }

    public enum CoverType
    {
        None,
        Light,
        Heavy
    }
}
