using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Economy;

namespace DustRTS.Territory
{
    /// <summary>
    /// Manages all sectors and territory control.
    /// </summary>
    public class TerritoryManager : MonoBehaviour
    {
        public static TerritoryManager Instance { get; private set; }

        [Header("Configuration")]
        [SerializeField] private List<Sector> sectors = new();

        private Dictionary<Team, int> sectorCounts = new();

        public IReadOnlyList<Sector> Sectors => sectors;
        public int TotalSectors => sectors.Count;

        public event Action<Team, int> OnSectorCountChanged;
        public event Action<Sector, Team> OnSectorCaptured;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            ServiceLocator.Register(this);
        }

        private void Start()
        {
            // Find all sectors if not assigned
            if (sectors.Count == 0)
            {
                sectors = FindObjectsByType<Sector>(FindObjectsSortMode.None).ToList();
            }

            // Subscribe to all sectors
            foreach (var sector in sectors)
            {
                sector.OnControlChanged += HandleSectorControlChanged;
            }

            // Initial count
            RecalculateSectorCounts();
        }

        public void RegisterSector(Sector sector)
        {
            if (!sectors.Contains(sector))
            {
                sectors.Add(sector);
                sector.OnControlChanged += HandleSectorControlChanged;
                RecalculateSectorCounts();
            }
        }

        public void UnregisterSector(Sector sector)
        {
            if (sectors.Contains(sector))
            {
                sectors.Remove(sector);
                sector.OnControlChanged -= HandleSectorControlChanged;
                RecalculateSectorCounts();
            }
        }

        private void HandleSectorControlChanged(Sector sector, Team newOwner, Team previousOwner)
        {
            // Update resource income
            var resourceManager = ServiceLocator.Get<ResourceManager>();
            if (resourceManager != null)
            {
                if (previousOwner != null)
                {
                    resourceManager.RemoveIncome(previousOwner, sector.NanoPasteBonus, sector.ISKBonus);
                }
                if (newOwner != null)
                {
                    resourceManager.AddIncome(newOwner, sector.NanoPasteBonus, sector.ISKBonus);
                }
            }

            // Recalculate counts
            RecalculateSectorCounts();

            // Notify match manager
            var matchManager = ServiceLocator.Get<MatchManager>();
            if (matchManager != null && newOwner != null)
            {
                matchManager.UpdateSectorControl(newOwner, GetSectorCount(newOwner));
            }

            OnSectorCaptured?.Invoke(sector, newOwner);
        }

        private void RecalculateSectorCounts()
        {
            sectorCounts.Clear();

            foreach (var sector in sectors)
            {
                var team = sector.ControllingTeam;
                if (team == null) continue;

                if (!sectorCounts.ContainsKey(team))
                    sectorCounts[team] = 0;
                sectorCounts[team]++;
            }

            foreach (var kvp in sectorCounts)
            {
                OnSectorCountChanged?.Invoke(kvp.Key, kvp.Value);
            }
        }

        public int GetSectorCount(Team team)
        {
            return sectorCounts.TryGetValue(team, out int count) ? count : 0;
        }

        public List<Sector> GetSectorsOwnedBy(Team team)
        {
            return sectors.Where(s => s.ControllingTeam == team).ToList();
        }

        public List<Sector> GetNeutralSectors()
        {
            return sectors.Where(s => s.IsNeutral).ToList();
        }

        public List<Sector> GetSectorsByType(SectorType type)
        {
            return sectors.Where(s => s.Type == type).ToList();
        }

        public Sector GetNearestSector(Vector3 position, Team team = null)
        {
            return sectors
                .Where(s => team == null || s.ControllingTeam == team)
                .OrderBy(s => Vector3.Distance(position, s.transform.position))
                .FirstOrDefault();
        }

        public Sector GetNearestUnownedSector(Vector3 position, Team myTeam)
        {
            return sectors
                .Where(s => s.ControllingTeam != myTeam)
                .OrderBy(s => Vector3.Distance(position, s.transform.position))
                .FirstOrDefault();
        }

        public bool DoesTeamControlMajority(Team team)
        {
            int count = GetSectorCount(team);
            return count > TotalSectors / 2;
        }

        private void OnDestroy()
        {
            foreach (var sector in sectors)
            {
                if (sector != null)
                {
                    sector.OnControlChanged -= HandleSectorControlChanged;
                }
            }

            if (Instance == this)
            {
                ServiceLocator.Unregister<TerritoryManager>();
            }
        }
    }
}
