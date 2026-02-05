# Boot Scene Specification

## Overview

The Boot scene is the **entry point** for Yokai Blade. It initializes persistent systems, displays the main menu, and manages scene transitions throughout the vertical slice.

**Scene Path:** `Assets/Game/Scenes/Boot.unity`

**Gate 1 Requirement:** *"Project builds, enters Boot scene"*

---

## Scene Flow

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│    Boot Scene                                               │
│    ══════════                                               │
│                                                             │
│    1. Initialize persistent managers (DontDestroyOnLoad)    │
│    2. Load TelegraphCatalog                                 │
│    3. Initialize audio system                               │
│    4. Display main menu                                     │
│                                                             │
│              ┌──────────────┐                               │
│              │  MAIN MENU   │                               │
│              ├──────────────┤                               │
│              │ ▶ BEGIN      │──────► Load ShirimeArena      │
│              │   OPTIONS    │──────► (future)               │
│              │   QUIT       │──────► Application.Quit()     │
│              └──────────────┘                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘

                          │
                          ▼

┌─────────────────────────────────────────────────────────────┐
│  Shirime Arena                                              │
│  ─────────────                                              │
│  Victory ──► Load TanukiArena                               │
│  Retry   ──► Reload ShirimeArena                            │
│  Quit    ──► Return to Boot (main menu)                     │
└─────────────────────────────────────────────────────────────┘

                          │
                          ▼

┌─────────────────────────────────────────────────────────────┐
│  Tanuki Arena                                               │
│  ────────────                                               │
│  Victory ──► Load OniArena                                  │
│  Retry   ──► Reload TanukiArena                             │
│  Quit    ──► Return to Boot (main menu)                     │
└─────────────────────────────────────────────────────────────┘

                          │
                          ▼

┌─────────────────────────────────────────────────────────────┐
│  Oni Arena                                                  │
│  ─────────                                                  │
│  Victory ──► Credits / Return to Boot                       │
│  Retry   ──► Reload OniArena                                │
│  Quit    ──► Return to Boot (main menu)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Scene Hierarchy

```
Boot (scene root)
├── --- MANAGERS (persistent) ---
├── [GameManager]
├── [SceneLoader]
├── [AudioManager]
├── [TelegraphManager]
├── --- CAMERA ---
├── Main Camera
├── --- UI ---
└── Canvas
    ├── TitleScreen
    │   ├── Title ("YOKAI BLADE")
    │   └── Subtitle ("Press Any Button")
    └── MainMenu
        ├── BeginButton
        ├── OptionsButton (disabled for vertical slice)
        └── QuitButton
```

**Note:** GameObjects in brackets `[Name]` use `DontDestroyOnLoad` and persist across scenes.

---

## Persistent Managers

### GameManager

Central game state controller. Persists across all scenes.

**Script:** `Assets/Core/Game/GameManager.cs`

```csharp
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    public GameState CurrentState { get; private set; }
    public int CurrentBossIndex { get; private set; }

    public event Action<GameState> OnStateChanged;

    // Scene names in order
    public static readonly string[] BossScenes = {
        "ShirimeArena",
        "TanukiArena",
        "OniArena"
    };
}
```

| Property | Type | Purpose |
|----------|------|---------|
| Instance | static | Singleton access |
| CurrentState | GameState | Menu, Playing, Paused, Victory, Dead |
| CurrentBossIndex | int | 0 = Shirime, 1 = Tanuki, 2 = Oni |

| Method | Purpose |
|--------|---------|
| StartGame() | Load first boss arena |
| AdvanceToNextBoss() | Load next arena or credits |
| RetryCurrentBoss() | Reload current arena |
| ReturnToMenu() | Load Boot scene |
| QuitGame() | Application.Quit() |

### SceneLoader

Handles async scene loading with optional transitions.

**Script:** `Assets/Core/Game/SceneLoader.cs`

| Method | Purpose |
|--------|---------|
| LoadScene(string name) | Async load with optional fade |
| ReloadCurrentScene() | Fast retry (no fade) |
| LoadSceneAdditive(string name) | For UI overlays |

### AudioManager

Manages music, SFX, and telegraph audio. Persists to maintain music across retries.

**Script:** `Assets/Core/Audio/AudioManager.cs`

| Property | Purpose |
|----------|---------|
| MusicVolume | 0.0 - 1.0 |
| SFXVolume | 0.0 - 1.0 |
| IsMuted | Global mute |

| Method | Purpose |
|--------|---------|
| PlayMusic(AudioClip) | Background music |
| PlaySFX(AudioClip) | One-shot sound |
| PlayTelegraph(TelegraphSemantic) | Telegraph audio cue |

### TelegraphManager

Initializes and holds the TelegraphCatalog reference.

**Script:** `Assets/Core/Telegraphs/TelegraphManager.cs`

| Property | Purpose |
|----------|---------|
| Catalog | Reference to TelegraphCatalog ScriptableObject |

---

## GameState Enum

```csharp
public enum GameState
{
    Initializing,   // Boot sequence
    MainMenu,       // At main menu
    Loading,        // Scene transition
    Playing,        // In gameplay
    Paused,         // Pause menu open
    Dead,           // Death feedback active
    Victory         // Boss defeated
}
```

---

## UI Screens

### Title Screen

Shown immediately on boot. Press any button to proceed.

| Element | Property | Value |
|---------|----------|-------|
| Title Text | Font Size | 72 |
| | Text | "YOKAI BLADE" |
| | Color | White |
| | Position | Center, upper third |
| Subtitle | Font Size | 24 |
| | Text | "Press Any Button" |
| | Color | Gray, pulsing alpha |
| | Position | Center, lower third |

**Behavior:**
- Fade in over 1 second
- Any input → Fade out, show Main Menu
- Subtitle pulses alpha (0.5 - 1.0, 1s cycle)

### Main Menu

Simple vertical button list.

| Element | Text | Action |
|---------|------|--------|
| Begin | "BEGIN" | GameManager.StartGame() |
| Options | "OPTIONS" | (disabled for vertical slice) |
| Quit | "QUIT" | GameManager.QuitGame() |

**Navigation:**
- Up/Down or W/S to select
- A/Enter/Space to confirm
- Selected button has highlight

**Layout:**
```
        YOKAI BLADE

        ▶ BEGIN
          OPTIONS
          QUIT
```

---

## Initialization Sequence

Order matters. Execute in `Awake()` / `Start()`:

```
1. GameManager.Initialize()
   └── Set Instance
   └── DontDestroyOnLoad(gameObject)
   └── CurrentState = Initializing

2. SceneLoader.Initialize()
   └── DontDestroyOnLoad(gameObject)

3. AudioManager.Initialize()
   └── DontDestroyOnLoad(gameObject)
   └── Load volume settings from PlayerPrefs

4. TelegraphManager.Initialize()
   └── DontDestroyOnLoad(gameObject)
   └── Load TelegraphCatalog asset
   └── Validate catalog entries

5. Show Title Screen
   └── Fade in
   └── Wait for input

6. Show Main Menu
   └── GameManager.CurrentState = MainMenu
```

---

## Scene Loading

### Load Boss Arena

```csharp
public void StartGame()
{
    CurrentBossIndex = 0;
    LoadBossArena(CurrentBossIndex);
}

private void LoadBossArena(int index)
{
    CurrentState = GameState.Loading;
    string sceneName = BossScenes[index];
    SceneLoader.LoadScene(sceneName, onComplete: () => {
        CurrentState = GameState.Playing;
    });
}
```

### Retry (Fast)

No fade, minimal delay. Maintains the "death is the teacher" philosophy.

```csharp
public void RetryCurrentBoss()
{
    CurrentState = GameState.Loading;
    SceneLoader.ReloadCurrentScene(fade: false, onComplete: () => {
        CurrentState = GameState.Playing;
    });
}
```

**Invariant:** *"Minimal friction between death and next attempt"*

### Victory → Next Boss

```csharp
public void AdvanceToNextBoss()
{
    CurrentBossIndex++;
    if (CurrentBossIndex >= BossScenes.Length)
    {
        // Vertical slice complete
        ShowCredits();
        return;
    }
    LoadBossArena(CurrentBossIndex);
}
```

### Return to Menu

```csharp
public void ReturnToMenu()
{
    CurrentState = GameState.Loading;
    SceneLoader.LoadScene("Boot", onComplete: () => {
        CurrentState = GameState.MainMenu;
    });
}
```

---

## Camera Setup

Static camera for menu. No gameplay here.

| Property | Value |
|----------|-------|
| Position | (0, 0, -10) |
| Rotation | (0, 0, 0) |
| Projection | Orthographic |
| Size | 5 |
| Clear Flags | Solid Color |
| Background | Black (#000000) |

---

## Lighting

Minimal. Menu is primarily UI.

| Property | Value |
|----------|-------|
| Ambient Mode | Color |
| Ambient Color | Dark (#0a0a0a) |
| No directional light needed | |

---

## Input Handling

### Title Screen
- Any button/key → Proceed to menu

### Main Menu
| Input | Action |
|-------|--------|
| Up / W / D-Pad Up | Select previous |
| Down / S / D-Pad Down | Select next |
| A / Enter / Space | Confirm selection |
| B / Escape | (no action at root menu) |

---

## Build Settings

The Boot scene must be **first** in Build Settings:

```
Scenes In Build:
  0: Assets/Game/Scenes/Boot.unity        ← Entry point
  1: Assets/Game/Scenes/ShirimeArena.unity
  2: Assets/Game/Scenes/TanukiArena.unity
  3: Assets/Game/Scenes/OniArena.unity
```

---

## PlayerPrefs Keys

For settings persistence (future):

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| MusicVolume | float | 1.0 | Music volume |
| SFXVolume | float | 1.0 | SFX volume |
| ScreenShake | int | 1 | 0 = off, 1 = on |

---

## Script Stubs

### GameManager.cs

```csharp
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YokaiBlade.Core.Game
{
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public static readonly string[] BossScenes = {
            "ShirimeArena",
            "TanukiArena",
            "OniArena"
        };

        public GameState CurrentState { get; private set; }
        public int CurrentBossIndex { get; private set; }

        private void Awake()
        {
            if (Instance != null)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            CurrentState = GameState.Initializing;
        }

        public void StartGame()
        {
            CurrentBossIndex = 0;
            LoadBossArena(CurrentBossIndex);
        }

        public void RetryCurrentBoss()
        {
            SceneManager.LoadScene(SceneManager.GetActiveScene().name);
            CurrentState = GameState.Playing;
        }

        public void AdvanceToNextBoss()
        {
            CurrentBossIndex++;
            if (CurrentBossIndex >= BossScenes.Length)
            {
                ReturnToMenu(); // Vertical slice complete
                return;
            }
            LoadBossArena(CurrentBossIndex);
        }

        public void ReturnToMenu()
        {
            SceneManager.LoadScene("Boot");
            CurrentState = GameState.MainMenu;
        }

        public void QuitGame()
        {
            #if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
            #else
            Application.Quit();
            #endif
        }

        private void LoadBossArena(int index)
        {
            CurrentState = GameState.Loading;
            SceneManager.LoadScene(BossScenes[index]);
            CurrentState = GameState.Playing;
        }
    }

    public enum GameState
    {
        Initializing,
        MainMenu,
        Loading,
        Playing,
        Paused,
        Dead,
        Victory
    }
}
```

### MainMenuUI.cs

```csharp
using UnityEngine;
using UnityEngine.UI;
using YokaiBlade.Core.Game;

namespace YokaiBlade.Core.UI
{
    public class MainMenuUI : MonoBehaviour
    {
        [SerializeField] private Button _beginButton;
        [SerializeField] private Button _optionsButton;
        [SerializeField] private Button _quitButton;

        private void Start()
        {
            _beginButton.onClick.AddListener(OnBegin);
            _optionsButton.onClick.AddListener(OnOptions);
            _quitButton.onClick.AddListener(OnQuit);

            // Disable options for vertical slice
            _optionsButton.interactable = false;

            // Select first button
            _beginButton.Select();
        }

        private void OnBegin()
        {
            GameManager.Instance.StartGame();
        }

        private void OnOptions()
        {
            // Not implemented for vertical slice
        }

        private void OnQuit()
        {
            GameManager.Instance.QuitGame();
        }
    }
}
```

---

## Testing Checklist

### Initialization
- [ ] Boot scene loads without errors
- [ ] GameManager persists (DontDestroyOnLoad)
- [ ] Title screen displays
- [ ] Press any button shows main menu

### Main Menu
- [ ] BEGIN loads ShirimeArena
- [ ] OPTIONS is disabled/grayed
- [ ] QUIT exits application
- [ ] Keyboard navigation works (W/S)
- [ ] Controller navigation works (D-Pad)
- [ ] Selection highlight visible

### Scene Flow
- [ ] ShirimeArena loads from menu
- [ ] Death → Retry reloads scene quickly
- [ ] Victory → Next boss loads TanukiArena
- [ ] Return to Menu loads Boot scene
- [ ] GameManager.CurrentBossIndex tracks correctly

### Persistence
- [ ] AudioManager persists across scenes
- [ ] Music continues during retry
- [ ] Volume settings preserved

---

## Gate 1 Acceptance Criteria

From PROJECT_PLAN.md:

> **Gate 1:** Project builds, enters Boot scene

Verification:
1. Build the project (File → Build and Run)
2. Application launches
3. Title screen appears
4. Press button → Main menu appears
5. BEGIN → Game loads without crash

---

## Future Enhancements (Post-Vertical Slice)

- [ ] Options menu (volume, controls, screen shake)
- [ ] Boss select (after completing once)
- [ ] Save/load progress
- [ ] Transition effects (fade, wipe)
- [ ] Attract mode (demo after idle)
- [ ] Credits screen
