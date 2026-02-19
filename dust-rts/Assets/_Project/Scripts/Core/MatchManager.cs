using System;
using System.Collections.Generic;
using UnityEngine;

namespace DustRTS.Core
{
    /// <summary>
    /// Manages the current match state.
    /// Tracks teams, victory points, and win conditions.
    /// Created fresh for each match.
    /// </summary>
    public class MatchManager : MonoBehaviour
    {
        public static MatchManager Instance { get; private set; }

        [Header("Teams")]
        [SerializeField] private Transform playerSpawnPoint;
        [SerializeField] private Transform enemySpawnPoint;

        private MatchSettings settings;
        private Dictionary<Team, MatchTeamState> teamStates = new();
        private List<Team> teams = new();
        private Team playerTeam;
        private Team enemyTeam;
        private Team neutralTeam;
        private float matchTime;
        private bool matchStarted;
        private bool matchEnded;

        public Team PlayerTeam => playerTeam;
        public Team EnemyTeam => enemyTeam;
        public Team NeutralTeam => neutralTeam;
        public IReadOnlyList<Team> Teams => teams;
        public float MatchTime => matchTime;
        public bool IsMatchActive => matchStarted && !matchEnded;
        public MatchSettings Settings => settings;

        public event Action OnMatchStart;
        public event Action<Team> OnMatchEnd;
        public event Action<Team, int> OnVictoryPointsChanged;
        public event Action<Team, int> OnSectorControlChanged;

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
            var gameManager = ServiceLocator.Get<GameManager>();
            settings = gameManager?.CurrentMatchSettings ?? MatchSettings.CreateDefault();

            InitializeTeams();
            StartMatch();
        }

        private void InitializeTeams()
        {
            // Create neutral team
            neutralTeam = Team.CreateNeutral();

            // Load faction selections or use defaults
            var playerFaction = (FactionType)PlayerPrefs.GetInt("PlayerFaction", (int)FactionType.Caldari);
            var enemyFaction = (FactionType)PlayerPrefs.GetInt("EnemyFaction", (int)FactionType.Minmatar);

            // Create player team
            playerTeam = new Team(
                id: 0,
                name: "Player",
                faction: playerFaction,
                color: GetFactionColor(playerFaction),
                isPlayer: true
            );

            // Create enemy team
            enemyTeam = new Team(
                id: 1,
                name: "Enemy",
                faction: enemyFaction,
                color: GetFactionColor(enemyFaction),
                isPlayer: false
            );

            teams.Add(playerTeam);
            teams.Add(enemyTeam);

            // Initialize team states
            foreach (var team in teams)
            {
                teamStates[team] = new MatchTeamState
                {
                    VictoryPoints = settings.StartingVictoryPoints,
                    SectorsControlled = 0
                };
            }
        }

        private Color GetFactionColor(FactionType faction)
        {
            return faction switch
            {
                FactionType.Amarr => new Color(0.9f, 0.75f, 0.2f),    // Gold
                FactionType.Caldari => new Color(0.3f, 0.5f, 0.8f),   // Blue-grey
                FactionType.Minmatar => new Color(0.7f, 0.3f, 0.2f),  // Rust red
                _ => Color.grey
            };
        }

        public void StartMatch()
        {
            if (matchStarted) return;

            matchStarted = true;
            matchTime = 0f;

            var gameManager = ServiceLocator.Get<GameManager>();
            gameManager?.SetState(GameState.Playing);

            Debug.Log("[MatchManager] Match started!");
            OnMatchStart?.Invoke();
        }

        private void Update()
        {
            if (!IsMatchActive) return;

            matchTime += Time.deltaTime;

            UpdateVictoryPointDrain();
            CheckWinConditions();
            CheckTimeLimit();
        }

        private void UpdateVictoryPointDrain()
        {
            foreach (var team in teams)
            {
                var state = teamStates[team];
                var enemyTeam = GetEnemyTeam(team);
                var enemyState = teamStates[enemyTeam];

                // Check if enemy controls enough sectors to drain
                if (enemyState.SectorsControlled >= settings.SectorsToControlForDrain)
                {
                    float drainRate = enemyState.SectorsControlled >= settings.TotalSectors
                        ? settings.VPDrainFullControl
                        : settings.VPDrainPerSecond;

                    state.VictoryPoints -= drainRate * Time.deltaTime;
                    state.VictoryPoints = Mathf.Max(0, state.VictoryPoints);

                    OnVictoryPointsChanged?.Invoke(team, Mathf.FloorToInt(state.VictoryPoints));
                }
            }
        }

        private void CheckWinConditions()
        {
            foreach (var team in teams)
            {
                var state = teamStates[team];
                if (state.VictoryPoints <= 0)
                {
                    var winner = GetEnemyTeam(team);
                    EndMatch(winner);
                    return;
                }
            }
        }

        private void CheckTimeLimit()
        {
            if (!settings.EnableTimeLimit) return;

            if (matchTime >= settings.MatchTimeLimitMinutes * 60f)
            {
                // Whoever has more VP wins
                Team winner = null;
                float highestVP = -1;

                foreach (var team in teams)
                {
                    var state = teamStates[team];
                    if (state.VictoryPoints > highestVP)
                    {
                        highestVP = state.VictoryPoints;
                        winner = team;
                    }
                }

                EndMatch(winner);
            }
        }

        public void EndMatch(Team winner)
        {
            if (matchEnded) return;

            matchEnded = true;

            var gameManager = ServiceLocator.Get<GameManager>();
            if (winner == playerTeam)
            {
                gameManager?.SetState(GameState.Victory);
            }
            else
            {
                gameManager?.SetState(GameState.Defeat);
            }

            Debug.Log($"[MatchManager] Match ended! Winner: {winner?.TeamName ?? "None"}");
            OnMatchEnd?.Invoke(winner);
        }

        public void UpdateSectorControl(Team team, int sectorsControlled)
        {
            if (!teamStates.ContainsKey(team)) return;

            var state = teamStates[team];
            state.SectorsControlled = sectorsControlled;

            OnSectorControlChanged?.Invoke(team, sectorsControlled);
        }

        public int GetVictoryPoints(Team team)
        {
            return teamStates.TryGetValue(team, out var state)
                ? Mathf.FloorToInt(state.VictoryPoints)
                : 0;
        }

        public int GetSectorsControlled(Team team)
        {
            return teamStates.TryGetValue(team, out var state)
                ? state.SectorsControlled
                : 0;
        }

        public Team GetEnemyTeam(Team team)
        {
            foreach (var t in teams)
            {
                if (t != team) return t;
            }
            return null;
        }

        public Transform GetSpawnPoint(Team team)
        {
            return team == playerTeam ? playerSpawnPoint : enemySpawnPoint;
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<MatchManager>();
            }
        }

        private class MatchTeamState
        {
            public float VictoryPoints;
            public int SectorsControlled;
        }
    }
}
