using System;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace DustRTS.Core
{
    /// <summary>
    /// Top-level game manager. Persists across scenes.
    /// Handles game state, scene transitions, and initialization.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        [Header("Configuration")]
        [SerializeField] private MatchSettings defaultMatchSettings;

        private GameState currentState = GameState.MainMenu;

        public GameState CurrentState => currentState;
        public MatchSettings CurrentMatchSettings { get; private set; }

        public event Action<GameState> OnGameStateChanged;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);

            ServiceLocator.Register(this);
            Application.quitting += ServiceLocator.OnApplicationQuitting;
        }

        private void Start()
        {
            if (defaultMatchSettings == null)
            {
                defaultMatchSettings = MatchSettings.CreateDefault();
            }
            CurrentMatchSettings = defaultMatchSettings;
        }

        public void SetState(GameState newState)
        {
            if (currentState == newState) return;

            var previousState = currentState;
            currentState = newState;

            Debug.Log($"[GameManager] State changed: {previousState} -> {newState}");
            OnGameStateChanged?.Invoke(newState);
        }

        public void StartSkirmish(MatchSettings settings = null)
        {
            CurrentMatchSettings = settings ?? defaultMatchSettings;
            SetState(GameState.Loading);
            SceneManager.LoadScene("Skirmish");
        }

        public void StartSkirmishWithSettings(MatchSettings settings, Team playerTeam, Team enemyTeam)
        {
            CurrentMatchSettings = settings ?? defaultMatchSettings;
            SetState(GameState.Loading);
            // Store team setup for MatchManager to read
            PlayerPrefs.SetInt("PlayerFaction", (int)playerTeam.Faction);
            PlayerPrefs.SetInt("EnemyFaction", (int)enemyTeam.Faction);
            SceneManager.LoadScene("Skirmish");
        }

        public void ReturnToMainMenu()
        {
            SetState(GameState.MainMenu);
            SceneManager.LoadScene("MainMenu");
        }

        public void QuitGame()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        public void PauseGame()
        {
            if (currentState == GameState.Playing)
            {
                Time.timeScale = 0f;
                SetState(GameState.Paused);
            }
        }

        public void ResumeGame()
        {
            if (currentState == GameState.Paused)
            {
                Time.timeScale = 1f;
                SetState(GameState.Playing);
            }
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<GameManager>();
                Application.quitting -= ServiceLocator.OnApplicationQuitting;
            }
        }
    }

    public enum GameState
    {
        MainMenu,
        Loading,
        Playing,
        Paused,
        Victory,
        Defeat
    }
}
