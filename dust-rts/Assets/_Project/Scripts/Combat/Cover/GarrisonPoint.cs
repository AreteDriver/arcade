using System.Collections.Generic;
using UnityEngine;
using DustRTS.Units.Infantry;

namespace DustRTS.Combat.Cover
{
    /// <summary>
    /// A building or structure that infantry can garrison inside.
    /// Provides maximum cover.
    /// </summary>
    public class GarrisonPoint : MonoBehaviour
    {
        [Header("Capacity")]
        [SerializeField] private int maxSquads = 2;

        [Header("Points")]
        [SerializeField] private Transform entryPoint;
        [SerializeField] private Transform exitPoint;
        [SerializeField] private Transform[] firingPositions;

        [Header("Visuals")]
        [SerializeField] private GameObject occupiedIndicator;

        private List<InfantrySquad> occupants = new();

        public int MaxSquads => maxSquads;
        public int CurrentOccupants => occupants.Count;
        public bool IsFull => occupants.Count >= maxSquads;
        public bool IsEmpty => occupants.Count == 0;
        public Transform EntryPoint => entryPoint ?? transform;
        public Transform ExitPoint => exitPoint ?? entryPoint ?? transform;
        public IReadOnlyList<InfantrySquad> Occupants => occupants;

        private void Awake()
        {
            if (occupiedIndicator != null)
            {
                occupiedIndicator.SetActive(false);
            }
        }

        public bool CanEnter(InfantrySquad squad)
        {
            if (squad == null) return false;
            if (IsFull) return false;
            if (occupants.Contains(squad)) return false;
            return true;
        }

        public bool AddOccupant(InfantrySquad squad)
        {
            if (!CanEnter(squad)) return false;

            occupants.Add(squad);
            UpdateVisuals();
            return true;
        }

        public bool RemoveOccupant(InfantrySquad squad)
        {
            if (squad == null) return false;

            bool removed = occupants.Remove(squad);
            if (removed)
            {
                UpdateVisuals();
            }
            return removed;
        }

        public void ClearOccupants()
        {
            // Force all occupants to exit
            foreach (var squad in occupants.ToArray())
            {
                squad.ExitGarrison();
            }
            occupants.Clear();
            UpdateVisuals();
        }

        private void UpdateVisuals()
        {
            if (occupiedIndicator != null)
            {
                occupiedIndicator.SetActive(!IsEmpty);
            }
        }

        public Transform GetFiringPosition(int index)
        {
            if (firingPositions == null || firingPositions.Length == 0)
                return transform;

            return firingPositions[index % firingPositions.Length];
        }

        public Vector3 GetEntryPosition()
        {
            return EntryPoint.position;
        }

        public Vector3 GetExitPosition()
        {
            return ExitPoint.position;
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.green;

            if (entryPoint != null)
            {
                Gizmos.DrawWireSphere(entryPoint.position, 0.5f);
                Gizmos.DrawLine(transform.position, entryPoint.position);
            }

            if (exitPoint != null)
            {
                Gizmos.color = Color.yellow;
                Gizmos.DrawWireSphere(exitPoint.position, 0.5f);
            }

            if (firingPositions != null)
            {
                Gizmos.color = Color.red;
                foreach (var pos in firingPositions)
                {
                    if (pos != null)
                    {
                        Gizmos.DrawWireSphere(pos.position, 0.3f);
                    }
                }
            }
        }
    }
}
