using System;
using System.Collections.Generic;
using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Economy
{
    /// <summary>
    /// Manages resources (Nanite Paste and ISK) for all teams.
    /// </summary>
    public class ResourceManager : MonoBehaviour
    {
        public static ResourceManager Instance { get; private set; }

        [Header("Starting Resources")]
        [SerializeField] private int startingNanoPaste = 500;
        [SerializeField] private int startingISK = 300;

        [Header("Base Income (per minute)")]
        [SerializeField] private int baseNanoPasteIncome = 50;
        [SerializeField] private int baseISKIncome = 20;

        [Header("Caps")]
        [SerializeField] private int maxNanoPaste = 1000;
        [SerializeField] private int maxISK = 2000;

        [Header("Kill Bounty")]
        [SerializeField] private float killBountyPercent = 0.1f;

        private Dictionary<Team, ResourceState> teamResources = new();

        public event Action<Team, int, int> OnResourcesChanged; // team, nanoPaste, isk
        public event Action<Team, int, int> OnIncomeChanged;    // team, npIncome, iskIncome

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
            // Get settings from match manager if available
            var matchManager = ServiceLocator.Get<MatchManager>();
            if (matchManager?.Settings != null)
            {
                var settings = matchManager.Settings;
                startingNanoPaste = settings.StartingNanoPaste;
                startingISK = settings.StartingISK;
                baseNanoPasteIncome = settings.BaseNanoPasteIncome;
                baseISKIncome = settings.BaseISKIncome;
                maxNanoPaste = settings.MaxNanoPaste;
                maxISK = settings.MaxISK;
            }

            // Initialize teams
            if (matchManager != null)
            {
                foreach (var team in matchManager.Teams)
                {
                    InitializeTeam(team);
                }
            }
        }

        public void InitializeTeam(Team team)
        {
            if (team == null) return;
            if (teamResources.ContainsKey(team)) return;

            teamResources[team] = new ResourceState
            {
                nanoPaste = startingNanoPaste,
                isk = startingISK,
                nanoPasteIncome = baseNanoPasteIncome,
                iskIncome = baseISKIncome
            };

            Debug.Log($"[ResourceManager] Initialized team {team.TeamName} with {startingNanoPaste} NP, {startingISK} ISK");
        }

        private void Update()
        {
            // Generate income
            foreach (var kvp in teamResources)
            {
                var team = kvp.Key;
                var state = kvp.Value;

                // Per-second income (divide by 60)
                float npGain = (state.nanoPasteIncome / 60f) * Time.deltaTime;
                float iskGain = (state.iskIncome / 60f) * Time.deltaTime;

                state.nanoPaste += npGain;
                state.isk += iskGain;

                // Cap
                state.nanoPaste = Mathf.Min(state.nanoPaste, maxNanoPaste);
                state.isk = Mathf.Min(state.isk, maxISK);

                teamResources[team] = state;
            }
        }

        public int GetNanoPaste(Team team)
        {
            return teamResources.TryGetValue(team, out var state)
                ? Mathf.FloorToInt(state.nanoPaste)
                : 0;
        }

        public int GetISK(Team team)
        {
            return teamResources.TryGetValue(team, out var state)
                ? Mathf.FloorToInt(state.isk)
                : 0;
        }

        public int GetNanoPasteIncome(Team team)
        {
            return teamResources.TryGetValue(team, out var state)
                ? state.nanoPasteIncome
                : 0;
        }

        public int GetISKIncome(Team team)
        {
            return teamResources.TryGetValue(team, out var state)
                ? state.iskIncome
                : 0;
        }

        public bool CanAfford(Team team, int nanoPaste, int isk)
        {
            if (!teamResources.TryGetValue(team, out var state)) return false;
            return state.nanoPaste >= nanoPaste && state.isk >= isk;
        }

        public bool SpendResources(Team team, int nanoPaste, int isk)
        {
            if (!CanAfford(team, nanoPaste, isk)) return false;

            var state = teamResources[team];
            state.nanoPaste -= nanoPaste;
            state.isk -= isk;
            teamResources[team] = state;

            OnResourcesChanged?.Invoke(team, GetNanoPaste(team), GetISK(team));
            return true;
        }

        public void AddResources(Team team, int nanoPaste, int isk)
        {
            if (!teamResources.TryGetValue(team, out var state)) return;

            state.nanoPaste += nanoPaste;
            state.isk += isk;
            state.nanoPaste = Mathf.Min(state.nanoPaste, maxNanoPaste);
            state.isk = Mathf.Min(state.isk, maxISK);
            teamResources[team] = state;

            OnResourcesChanged?.Invoke(team, GetNanoPaste(team), GetISK(team));
        }

        public void AddIncome(Team team, int nanoPasteBonus, int iskBonus)
        {
            if (!teamResources.TryGetValue(team, out var state)) return;

            state.nanoPasteIncome += nanoPasteBonus;
            state.iskIncome += iskBonus;
            teamResources[team] = state;

            OnIncomeChanged?.Invoke(team, state.nanoPasteIncome, state.iskIncome);
        }

        public void RemoveIncome(Team team, int nanoPasteBonus, int iskBonus)
        {
            if (!teamResources.TryGetValue(team, out var state)) return;

            state.nanoPasteIncome = Mathf.Max(0, state.nanoPasteIncome - nanoPasteBonus);
            state.iskIncome = Mathf.Max(0, state.iskIncome - iskBonus);
            teamResources[team] = state;

            OnIncomeChanged?.Invoke(team, state.nanoPasteIncome, state.iskIncome);
        }

        public void AddKillBounty(Team team, int killedUnitValue)
        {
            int bounty = Mathf.RoundToInt(killedUnitValue * killBountyPercent);
            if (bounty <= 0) return;

            AddResources(team, 0, bounty);
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<ResourceManager>();
            }
        }

        private class ResourceState
        {
            public float nanoPaste;
            public float isk;
            public int nanoPasteIncome;
            public int iskIncome;
        }
    }
}
