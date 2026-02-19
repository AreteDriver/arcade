# DUST ORBITAL COMMAND RTS — CLAUDE CODE BUILD PROMPT

You are building a real-time strategy game called **DUST Orbital Command**. Corporate factions wage war for planetary control using infantry, vehicles, aircraft, and orbital strikes. This is a top-down RTS in the style of Company of Heroes meets the DUST 514/EVE universe.

Read this entire prompt before writing any code. Understand the vision, then execute systematically.

---

## GAME VISION

**Core Fantasy:** You are the commander. The war bends to your will. Infantry push through contested streets, tanks break enemy lines, dropships deliver reinforcements, and orbital fire rains from the sky at your command.

**Inspirations:**
- Company of Heroes (squad-based combat, cover, combined arms)
- Wargame: Red Dragon (deck building, no base building, deployment)
- Supreme Commander (scale, strategic zoom)
- DUST 514 / EVE Online (faction warfare, orbital strikes, war economy)
- Command & Conquer (superweapons, clear faction identity)

**Key Differentiators:**
- Orbital strike system tied to territorial control
- Three asymmetric factions (Amarr, Caldari, Minmatar)
- War economy where losses matter
- Combined arms where every unit type is essential

---

## TECHNICAL STACK

```
Engine: Unity 6 (6000.x)
Language: C# 11+
Input: Unity Input System
Pathfinding: Unity NavMesh + Flow Field for large groups
UI: UI Toolkit
Audio: Unity Audio
```

**Architecture Principles:**
- SOLID principles throughout
- ScriptableObjects for all unit/weapon/faction data
- Events and delegates for decoupling
- Object pooling for projectiles and effects
- ECS-inspired data separation where practical
- Clear module boundaries

---

## PROJECT STRUCTURE

```
Assets/
├── _Project/
│   ├── Scenes/
│   │   ├── Boot.unity
│   │   ├── MainMenu.unity
│   │   ├── Skirmish.unity
│   │   └── TestMap.unity
│   │
│   ├── Scripts/
│   │   ├── Core/
│   │   │   ├── GameManager.cs
│   │   │   ├── MatchManager.cs
│   │   │   ├── MatchSettings.cs
│   │   │   ├── Team.cs
│   │   │   └── ServiceLocator.cs
│   │   │
│   │   ├── Input/
│   │   │   ├── InputManager.cs
│   │   │   ├── RTSInputActions.inputactions
│   │   │   └── CameraInput.cs
│   │   │
│   │   ├── Camera/
│   │   │   ├── RTSCamera.cs
│   │   │   ├── CameraBounds.cs
│   │   │   ├── StrategicZoom.cs
│   │   │   └── MinimapCamera.cs
│   │   │
│   │   ├── Selection/
│   │   │   ├── SelectionManager.cs
│   │   │   ├── Selectable.cs
│   │   │   ├── SelectionBox.cs
│   │   │   ├── ControlGroup.cs
│   │   │   └── CommandSystem.cs
│   │   │
│   │   ├── Units/
│   │   │   ├── Core/
│   │   │   │   ├── Unit.cs
│   │   │   │   ├── UnitData.cs
│   │   │   │   ├── UnitStats.cs
│   │   │   │   ├── UnitHealth.cs
│   │   │   │   └── UnitMovement.cs
│   │   │   │
│   │   │   ├── Infantry/
│   │   │   │   ├── InfantrySquad.cs
│   │   │   │   ├── SquadMember.cs
│   │   │   │   ├── SquadFormation.cs
│   │   │   │   └── InfantryTypes/
│   │   │   │       ├── RifleSquad.cs
│   │   │   │       ├── AssaultSquad.cs
│   │   │   │       ├── HeavyWeaponsSquad.cs
│   │   │   │       └── SniperTeam.cs
│   │   │   │
│   │   │   ├── Vehicles/
│   │   │   │   ├── Vehicle.cs
│   │   │   │   ├── VehicleData.cs
│   │   │   │   ├── Transport.cs
│   │   │   │   └── VehicleTypes/
│   │   │   │       ├── LAV.cs
│   │   │   │       ├── APC.cs
│   │   │   │       ├── Tank.cs
│   │   │   │       └── HeavyTank.cs
│   │   │   │
│   │   │   ├── Aircraft/
│   │   │   │   ├── Aircraft.cs
│   │   │   │   ├── AircraftData.cs
│   │   │   │   └── AircraftTypes/
│   │   │   │       ├── Dropship.cs
│   │   │   │       ├── Gunship.cs
│   │   │   │       └── Fighter.cs
│   │   │   │
│   │   │   ├── Structures/
│   │   │   │   ├── Structure.cs
│   │   │   │   ├── Turret.cs
│   │   │   │   ├── ShieldGenerator.cs
│   │   │   │   └── HQ.cs
│   │   │   │
│   │   │   └── Abilities/
│   │   │       ├── UnitAbility.cs
│   │   │       ├── GrenadeAbility.cs
│   │   │       ├── SprintAbility.cs
│   │   │       ├── DeployAbility.cs
│   │   │       └── SmokeAbility.cs
│   │   │
│   │   ├── Combat/
│   │   │   ├── Weapons/
│   │   │   │   ├── Weapon.cs
│   │   │   │   ├── WeaponData.cs
│   │   │   │   ├── HitscanWeapon.cs
│   │   │   │   ├── ProjectileWeapon.cs
│   │   │   │   └── Projectile.cs
│   │   │   │
│   │   │   ├── Damage/
│   │   │   │   ├── DamageSystem.cs
│   │   │   │   ├── DamageInfo.cs
│   │   │   │   ├── ArmorSystem.cs
│   │   │   │   └── DamageTypes.cs
│   │   │   │
│   │   │   ├── Cover/
│   │   │   │   ├── CoverSystem.cs
│   │   │   │   ├── CoverPoint.cs
│   │   │   │   ├── CoverDetector.cs
│   │   │   │   └── GarrisonPoint.cs
│   │   │   │
│   │   │   ├── Suppression/
│   │   │   │   ├── SuppressionSystem.cs
│   │   │   │   ├── SuppressionState.cs
│   │   │   │   └── MoraleSystem.cs
│   │   │   │
│   │   │   └── Effects/
│   │   │       ├── MuzzleFlash.cs
│   │   │       ├── Impact.cs
│   │   │       ├── Explosion.cs
│   │   │       └── TracerEffect.cs
│   │   │
│   │   ├── Territory/
│   │   │   ├── TerritoryManager.cs
│   │   │   ├── Sector.cs
│   │   │   ├── CapturePoint.cs
│   │   │   ├── ResourceNode.cs
│   │   │   └── VictoryPointSystem.cs
│   │   │
│   │   ├── Orbital/
│   │   │   ├── OrbitalManager.cs
│   │   │   ├── UplinkStation.cs
│   │   │   ├── OrbitalStrike.cs
│   │   │   ├── StrikeTypes/
│   │   │   │   ├── PrecisionStrike.cs
│   │   │   │   ├── Bombardment.cs
│   │   │   │   ├── EMPStrike.cs
│   │   │   │   └── OrbitalLaser.cs
│   │   │   └── OrbitalEffects.cs
│   │   │
│   │   ├── Economy/
│   │   │   ├── ResourceManager.cs
│   │   │   ├── ResourceType.cs
│   │   │   ├── Income.cs
│   │   │   └── Cost.cs
│   │   │
│   │   ├── Production/
│   │   │   ├── ProductionManager.cs
│   │   │   ├── ProductionQueue.cs
│   │   │   ├── UnitFactory.cs
│   │   │   └── DeploymentManager.cs
│   │   │
│   │   ├── AI/
│   │   │   ├── UnitAI/
│   │   │   │   ├── UnitAI.cs
│   │   │   │   ├── AttackBehavior.cs
│   │   │   │   ├── MoveBehavior.cs
│   │   │   │   ├── CoverBehavior.cs
│   │   │   │   └── IdleBehavior.cs
│   │   │   │
│   │   │   └── CommanderAI/
│   │   │       ├── AICommander.cs
│   │   │       ├── AIStrategy.cs
│   │   │       ├── BuildOrder.cs
│   │   │       └── TacticalDecision.cs
│   │   │
│   │   ├── Pathfinding/
│   │   │   ├── PathfindingManager.cs
│   │   │   ├── FlowField.cs
│   │   │   ├── FlowFieldGenerator.cs
│   │   │   └── FormationMovement.cs
│   │   │
│   │   ├── Factions/
│   │   │   ├── Faction.cs
│   │   │   ├── FactionData.cs
│   │   │   ├── FactionAbility.cs
│   │   │   └── Factions/
│   │   │       ├── AmarrFaction.cs
│   │   │       ├── CaldariFaction.cs
│   │   │       └── MinmatarFaction.cs
│   │   │
│   │   ├── UI/
│   │   │   ├── HUD/
│   │   │   │   ├── HUDManager.cs
│   │   │   │   ├── ResourceDisplay.cs
│   │   │   │   ├── SelectionPanel.cs
│   │   │   │   ├── AbilityBar.cs
│   │   │   │   ├── MinimapUI.cs
│   │   │   │   └── UplinkStatus.cs
│   │   │   │
│   │   │   ├── Production/
│   │   │   │   ├── ProductionPanel.cs
│   │   │   │   ├── UnitCard.cs
│   │   │   │   └── QueueDisplay.cs
│   │   │   │
│   │   │   ├── Orbital/
│   │   │   │   ├── OrbitalMenu.cs
│   │   │   │   ├── StrikeTargeting.cs
│   │   │   │   └── StrikeIndicator.cs
│   │   │   │
│   │   │   ├── World/
│   │   │   │   ├── HealthBar.cs
│   │   │   │   ├── SelectionRing.cs
│   │   │   │   ├── CaptureProgress.cs
│   │   │   │   └── UnitIcon.cs
│   │   │   │
│   │   │   └── Menus/
│   │   │       ├── MainMenu.cs
│   │   │       ├── SkirmishSetup.cs
│   │   │       ├── FactionSelect.cs
│   │   │       └── PauseMenu.cs
│   │   │
│   │   └── Utility/
│   │       ├── Extensions.cs
│   │       ├── ObjectPool.cs
│   │       ├── Timer.cs
│   │       ├── MathUtils.cs
│   │       └── DebugDraw.cs
│   │
│   ├── Data/
│   │   ├── Units/
│   │   │   ├── Infantry/
│   │   │   │   ├── RifleSquad.asset
│   │   │   │   ├── AssaultSquad.asset
│   │   │   │   ├── HeavyWeapons.asset
│   │   │   │   └── SniperTeam.asset
│   │   │   │
│   │   │   ├── Vehicles/
│   │   │   │   ├── LAV.asset
│   │   │   │   ├── APC.asset
│   │   │   │   ├── Tank.asset
│   │   │   │   └── HeavyTank.asset
│   │   │   │
│   │   │   └── Aircraft/
│   │   │       ├── Dropship.asset
│   │   │       ├── Gunship.asset
│   │   │       └── Fighter.asset
│   │   │
│   │   ├── Weapons/
│   │   │   ├── Rifle.asset
│   │   │   ├── SMG.asset
│   │   │   ├── LMG.asset
│   │   │   ├── RocketLauncher.asset
│   │   │   ├── TankCannon.asset
│   │   │   └── Autocannon.asset
│   │   │
│   │   ├── Factions/
│   │   │   ├── Amarr.asset
│   │   │   ├── Caldari.asset
│   │   │   └── Minmatar.asset
│   │   │
│   │   └── Orbital/
│   │       ├── PrecisionStrike.asset
│   │       ├── Bombardment.asset
│   │       ├── EMPStrike.asset
│   │       └── OrbitalLaser.asset
│   │
│   ├── Prefabs/
│   │   ├── Units/
│   │   ├── Weapons/
│   │   ├── Effects/
│   │   ├── Structures/
│   │   └── UI/
│   │
│   ├── Art/
│   │   ├── Materials/
│   │   ├── Textures/
│   │   └── Models/
│   │
│   └── Audio/
│       ├── SFX/
│       ├── Voice/
│       └── Music/
│
├── Settings/
│   └── RTSInputActions.inputactions
│
└── Plugins/
```

---

## CORE SYSTEMS SPECIFICATION

### 1. CAMERA SYSTEM

**Requirements:**
- Pan with WASD/Arrow Keys/Edge scroll/Middle mouse drag
- Zoom with scroll wheel (strategic zoom)
- Rotate with Q/E (optional)
- Minimap click to jump
- Smooth movement with acceleration/deceleration
- Camera bounds to prevent leaving map

**RTSCamera.cs Core:**

```csharp
public class RTSCamera : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float panSpeed = 30f;
    [SerializeField] private float panAcceleration = 50f;
    [SerializeField] private float edgeScrollThreshold = 20f;
    [SerializeField] private bool enableEdgeScroll = true;
    
    [Header("Zoom")]
    [SerializeField] private float minHeight = 15f;
    [SerializeField] private float maxHeight = 80f;
    [SerializeField] private float zoomSpeed = 10f;
    [SerializeField] private float zoomSmoothing = 5f;
    
    [Header("Rotation")]
    [SerializeField] private float rotationSpeed = 90f;
    [SerializeField] private bool enableRotation = true;
    
    [Header("Bounds")]
    [SerializeField] private Bounds cameraBounds;
    
    private Vector3 currentVelocity;
    private float targetHeight;
    private float targetRotation;
    
    void Update()
    {
        HandlePanning();
        HandleZoom();
        HandleRotation();
        ApplyBounds();
    }
    
    void HandlePanning()
    {
        Vector3 input = Vector3.zero;
        
        // Keyboard input
        input.x = Input.GetAxisRaw("Horizontal");
        input.z = Input.GetAxisRaw("Vertical");
        
        // Edge scrolling
        if (enableEdgeScroll)
        {
            Vector2 mouse = Input.mousePosition;
            if (mouse.x < edgeScrollThreshold) input.x -= 1;
            if (mouse.x > Screen.width - edgeScrollThreshold) input.x += 1;
            if (mouse.y < edgeScrollThreshold) input.z -= 1;
            if (mouse.y > Screen.height - edgeScrollThreshold) input.z += 1;
        }
        
        // Middle mouse drag
        if (Input.GetMouseButton(2))
        {
            input.x -= Input.GetAxis("Mouse X") * 2f;
            input.z -= Input.GetAxis("Mouse Y") * 2f;
        }
        
        // Apply movement relative to camera rotation
        Vector3 forward = transform.forward;
        forward.y = 0;
        forward.Normalize();
        Vector3 right = transform.right;
        right.y = 0;
        right.Normalize();
        
        Vector3 targetVelocity = (forward * input.z + right * input.x) * panSpeed;
        
        // Smooth acceleration
        currentVelocity = Vector3.Lerp(currentVelocity, targetVelocity, 
            Time.deltaTime * panAcceleration);
        
        transform.position += currentVelocity * Time.deltaTime;
    }
    
    void HandleZoom()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        targetHeight -= scroll * zoomSpeed;
        targetHeight = Mathf.Clamp(targetHeight, minHeight, maxHeight);
        
        Vector3 pos = transform.position;
        pos.y = Mathf.Lerp(pos.y, targetHeight, Time.deltaTime * zoomSmoothing);
        transform.position = pos;
        
        // Adjust camera angle based on height (more top-down when zoomed out)
        float t = (pos.y - minHeight) / (maxHeight - minHeight);
        float angle = Mathf.Lerp(45f, 70f, t);
        transform.rotation = Quaternion.Euler(angle, transform.eulerAngles.y, 0);
    }
    
    public void JumpToPosition(Vector3 position)
    {
        position.y = transform.position.y;
        transform.position = position;
    }
}
```

---

### 2. SELECTION SYSTEM

**Requirements:**
- Click to select single unit
- Drag box to select multiple units
- Shift+click to add to selection
- Ctrl+click to toggle selection
- Double-click to select all of same type on screen
- Control groups (1-9)
- Right-click to issue commands

**SelectionManager.cs Core:**

```csharp
public class SelectionManager : MonoBehaviour
{
    public static SelectionManager Instance { get; private set; }
    
    [Header("Selection")]
    [SerializeField] private LayerMask selectableLayer;
    [SerializeField] private LayerMask groundLayer;
    [SerializeField] private RectTransform selectionBox;
    
    private List<Unit> selectedUnits = new();
    private List<Unit> previewUnits = new(); // For box select preview
    private Vector2 boxStartPosition;
    private bool isBoxSelecting;
    
    // Control groups
    private Dictionary<int, List<Unit>> controlGroups = new();
    
    public IReadOnlyList<Unit> SelectedUnits => selectedUnits;
    public event System.Action<List<Unit>> OnSelectionChanged;
    
    void Update()
    {
        HandleSelectionInput();
        HandleCommandInput();
        HandleControlGroups();
    }
    
    void HandleSelectionInput()
    {
        // Start box select
        if (Input.GetMouseButtonDown(0) && !IsPointerOverUI())
        {
            boxStartPosition = Input.mousePosition;
            isBoxSelecting = true;
        }
        
        // Update box select
        if (isBoxSelecting)
        {
            UpdateSelectionBox();
            UpdatePreviewSelection();
        }
        
        // End box select
        if (Input.GetMouseButtonUp(0) && isBoxSelecting)
        {
            CompleteSelection();
            isBoxSelecting = false;
            selectionBox.gameObject.SetActive(false);
        }
        
        // Double click - select all of same type
        if (Input.GetMouseButtonDown(0) && IsDoubleClick())
        {
            SelectAllOfTypeOnScreen();
        }
    }
    
    void HandleCommandInput()
    {
        if (Input.GetMouseButtonDown(1) && selectedUnits.Count > 0)
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            
            if (Physics.Raycast(ray, out RaycastHit hit, 1000f))
            {
                // Check what we clicked on
                if (hit.collider.TryGetComponent<Unit>(out var targetUnit))
                {
                    if (targetUnit.Team != selectedUnits[0].Team)
                    {
                        // Attack command
                        IssueAttackCommand(targetUnit);
                    }
                    else
                    {
                        // Support/follow command
                        IssueSupportCommand(targetUnit);
                    }
                }
                else if (hit.collider.TryGetComponent<CapturePoint>(out var capturePoint))
                {
                    // Capture command
                    IssueCaptureCommand(capturePoint);
                }
                else
                {
                    // Move command
                    IssueMoveCommand(hit.point);
                }
            }
        }
        
        // Attack-move (A + click)
        if (Input.GetKeyDown(KeyCode.A))
        {
            StartAttackMoveMode();
        }
    }
    
    void HandleControlGroups()
    {
        for (int i = 1; i <= 9; i++)
        {
            KeyCode key = KeyCode.Alpha0 + i;
            
            if (Input.GetKeyDown(key))
            {
                if (Input.GetKey(KeyCode.LeftControl))
                {
                    // Assign control group
                    AssignControlGroup(i, selectedUnits);
                }
                else
                {
                    // Select control group
                    SelectControlGroup(i, Input.GetKey(KeyCode.LeftShift));
                }
            }
        }
    }
    
    public void Select(Unit unit, bool additive = false)
    {
        if (!additive) ClearSelection();
        
        if (!selectedUnits.Contains(unit))
        {
            selectedUnits.Add(unit);
            unit.OnSelected();
        }
        
        OnSelectionChanged?.Invoke(selectedUnits);
    }
    
    public void ClearSelection()
    {
        foreach (var unit in selectedUnits)
        {
            unit.OnDeselected();
        }
        selectedUnits.Clear();
        OnSelectionChanged?.Invoke(selectedUnits);
    }
    
    void IssueMoveCommand(Vector3 position)
    {
        // Formation-based positioning
        var positions = FormationCalculator.GetFormationPositions(
            position, selectedUnits.Count, FormationType.Box);
        
        for (int i = 0; i < selectedUnits.Count; i++)
        {
            bool queue = Input.GetKey(KeyCode.LeftShift);
            selectedUnits[i].MoveTo(positions[i], queue);
        }
        
        // Visual feedback
        SpawnMoveIndicator(position);
    }
    
    void IssueAttackCommand(Unit target)
    {
        foreach (var unit in selectedUnits)
        {
            bool queue = Input.GetKey(KeyCode.LeftShift);
            unit.AttackTarget(target, queue);
        }
        
        // Visual feedback
        SpawnAttackIndicator(target.transform.position);
    }
}
```

---

### 3. UNIT SYSTEM

**Unit.cs Base Class:**

```csharp
public abstract class Unit : MonoBehaviour
{
    [Header("Data")]
    [SerializeField] protected UnitData unitData;
    
    [Header("Components")]
    [SerializeField] protected UnitHealth health;
    [SerializeField] protected UnitMovement movement;
    [SerializeField] protected Weapon weapon;
    
    public Team Team { get; private set; }
    public UnitData Data => unitData;
    public bool IsSelected { get; private set; }
    public bool IsAlive => health.IsAlive;
    
    // Combat state
    public Unit CurrentTarget { get; protected set; }
    public bool IsInCombat { get; protected set; }
    
    // Veterancy
    public int KillCount { get; private set; }
    public VeterancyLevel Veterancy { get; private set; }
    
    // Events
    public event System.Action<Unit> OnKilled;
    public event System.Action<Unit> OnTargetAcquired;
    
    protected virtual void Awake()
    {
        health.OnDeath += HandleDeath;
    }
    
    public virtual void Initialize(Team team)
    {
        Team = team;
        health.Initialize(unitData.maxHealth);
    }
    
    public virtual void MoveTo(Vector3 position, bool queue = false)
    {
        if (queue)
            movement.QueueDestination(position);
        else
            movement.SetDestination(position);
    }
    
    public virtual void AttackTarget(Unit target, bool queue = false)
    {
        CurrentTarget = target;
        OnTargetAcquired?.Invoke(target);
        
        // Move into range if needed
        float range = weapon.Data.range;
        float distance = Vector3.Distance(transform.position, target.transform.position);
        
        if (distance > range)
        {
            Vector3 direction = (target.transform.position - transform.position).normalized;
            Vector3 attackPosition = target.transform.position - direction * (range * 0.8f);
            MoveTo(attackPosition, queue);
        }
    }
    
    public virtual void Stop()
    {
        movement.Stop();
        CurrentTarget = null;
    }
    
    public virtual void HoldPosition()
    {
        movement.Stop();
        // Will still engage targets in range but won't move
    }
    
    protected virtual void Update()
    {
        if (!IsAlive) return;
        
        UpdateCombat();
        UpdateVeterancy();
    }
    
    protected virtual void UpdateCombat()
    {
        // Validate current target
        if (CurrentTarget != null && !CurrentTarget.IsAlive)
        {
            CurrentTarget = null;
        }
        
        // Auto-acquire targets if none
        if (CurrentTarget == null)
        {
            CurrentTarget = FindNearestEnemy();
        }
        
        // Fire at target if in range
        if (CurrentTarget != null && weapon.CanFire())
        {
            float distance = Vector3.Distance(transform.position, CurrentTarget.transform.position);
            if (distance <= weapon.Data.range)
            {
                weapon.Fire(CurrentTarget);
            }
        }
    }
    
    protected Unit FindNearestEnemy()
    {
        var enemies = UnitManager.Instance.GetEnemyUnits(Team);
        return enemies
            .Where(e => e.IsAlive)
            .OrderBy(e => Vector3.Distance(transform.position, e.transform.position))
            .FirstOrDefault(e => Vector3.Distance(transform.position, e.transform.position) <= unitData.sightRange);
    }
    
    public void RegisterKill()
    {
        KillCount++;
        UpdateVeterancy();
    }
    
    void UpdateVeterancy()
    {
        Veterancy = KillCount switch
        {
            >= 30 => VeterancyLevel.Elite,
            >= 15 => VeterancyLevel.Veteran,
            >= 5 => VeterancyLevel.Experienced,
            _ => VeterancyLevel.Rookie
        };
    }
    
    public float GetVeterancyModifier()
    {
        return Veterancy switch
        {
            VeterancyLevel.Elite => 1.3f,
            VeterancyLevel.Veteran => 1.2f,
            VeterancyLevel.Experienced => 1.1f,
            _ => 1f
        };
    }
    
    protected virtual void HandleDeath()
    {
        OnKilled?.Invoke(this);
        // Play death effects, start ragdoll, etc.
    }
    
    public virtual void OnSelected()
    {
        IsSelected = true;
        // Show selection ring, play sound
    }
    
    public virtual void OnDeselected()
    {
        IsSelected = false;
        // Hide selection ring
    }
}

public enum VeterancyLevel { Rookie, Experienced, Veteran, Elite }
```

**UnitData.cs (ScriptableObject):**

```csharp
[CreateAssetMenu(fileName = "Unit", menuName = "RTS/Unit Data")]
public class UnitData : ScriptableObject
{
    [Header("Identity")]
    public string unitName;
    public string description;
    public Sprite icon;
    public UnitType unitType;
    public Faction faction;
    
    [Header("Stats")]
    public int maxHealth = 100;
    public float armor = 0f;
    public float moveSpeed = 5f;
    public float rotationSpeed = 180f;
    public float sightRange = 30f;
    
    [Header("Cost")]
    public int nanoPasteCost;
    public int iskCost;
    public float buildTime = 10f;
    
    [Header("Combat")]
    public WeaponData primaryWeapon;
    public WeaponData secondaryWeapon;
    public float suppressionResistance = 0f;
    
    [Header("Abilities")]
    public UnitAbility[] abilities;
    
    [Header("Flags")]
    public bool canCapture = false;
    public bool canGarrison = false;
    public bool canTransport = false;
    public int transportCapacity = 0;
    
    [Header("Audio")]
    public AudioClip selectSound;
    public AudioClip moveSound;
    public AudioClip attackSound;
    public AudioClip deathSound;
}

public enum UnitType { Infantry, Vehicle, Aircraft, Structure }
```

---

### 4. INFANTRY SQUAD SYSTEM

Infantry operates as squads, not individual soldiers.

**InfantrySquad.cs:**

```csharp
public class InfantrySquad : Unit
{
    [Header("Squad")]
    [SerializeField] private int maxSquadSize = 4;
    [SerializeField] private SquadMember memberPrefab;
    [SerializeField] private SquadFormation formation;
    
    private List<SquadMember> members = new();
    
    public int CurrentSize => members.Count(m => m.IsAlive);
    public bool IsWiped => CurrentSize == 0;
    
    // Cover state
    public CoverState CurrentCover { get; private set; }
    public bool IsGarrisoned { get; private set; }
    
    // Suppression state
    public float SuppressionLevel { get; private set; }
    public bool IsSuppressed => SuppressionLevel > 0.5f;
    public bool IsPinned => SuppressionLevel > 0.8f;
    
    protected override void Awake()
    {
        base.Awake();
        SpawnSquadMembers();
    }
    
    void SpawnSquadMembers()
    {
        for (int i = 0; i < maxSquadSize; i++)
        {
            var member = Instantiate(memberPrefab, transform);
            member.Initialize(this, i);
            members.Add(member);
        }
    }
    
    protected override void Update()
    {
        base.Update();
        
        UpdateFormation();
        UpdateCover();
        UpdateSuppression();
    }
    
    void UpdateFormation()
    {
        var positions = formation.GetPositions(transform.position, transform.forward, CurrentSize);
        
        for (int i = 0; i < members.Count; i++)
        {
            if (members[i].IsAlive && i < positions.Count)
            {
                members[i].SetTargetPosition(positions[i]);
            }
        }
    }
    
    void UpdateCover()
    {
        if (IsGarrisoned)
        {
            CurrentCover = CoverState.Garrison;
            return;
        }
        
        // Check nearby cover points
        var coverPoints = Physics.OverlapSphere(transform.position, 3f, coverLayer);
        
        if (coverPoints.Length > 0)
        {
            // Determine cover quality based on direction to threat
            Vector3 threatDirection = CurrentTarget != null ? 
                (CurrentTarget.transform.position - transform.position).normalized : 
                Vector3.zero;
            
            CurrentCover = EvaluateCover(coverPoints, threatDirection);
        }
        else
        {
            CurrentCover = CoverState.None;
        }
    }
    
    void UpdateSuppression()
    {
        // Decay suppression over time
        SuppressionLevel -= Time.deltaTime * 0.2f;
        SuppressionLevel = Mathf.Clamp01(SuppressionLevel);
    }
    
    public void ApplySuppression(float amount)
    {
        amount *= (1f - unitData.suppressionResistance);
        SuppressionLevel += amount;
        SuppressionLevel = Mathf.Clamp01(SuppressionLevel);
    }
    
    public override void MoveTo(Vector3 position, bool queue = false)
    {
        // Leave garrison if moving
        if (IsGarrisoned)
        {
            ExitGarrison();
        }
        
        base.MoveTo(position, queue);
    }
    
    public void EnterGarrison(GarrisonPoint garrison)
    {
        if (!unitData.canGarrison) return;
        
        IsGarrisoned = true;
        garrison.OccupyWith(this);
        
        // Hide squad members visually
        foreach (var member in members)
        {
            member.SetVisible(false);
        }
    }
    
    public void ExitGarrison()
    {
        IsGarrisoned = false;
        
        foreach (var member in members)
        {
            member.SetVisible(true);
        }
    }
    
    public float GetDamageReduction()
    {
        return CurrentCover switch
        {
            CoverState.Garrison => 0.75f,
            CoverState.Heavy => 0.5f,
            CoverState.Light => 0.25f,
            _ => 0f
        };
    }
    
    public void TakeCasualty(SquadMember member)
    {
        // One member dies
        member.Kill();
        
        // Check for wipe
        if (IsWiped)
        {
            HandleDeath();
        }
        else
        {
            // Morale hit for losing squad member
            ApplySuppression(0.2f);
        }
    }
}

public enum CoverState { None, Light, Heavy, Garrison }
```

---

### 5. VEHICLE SYSTEM

**Vehicle.cs:**

```csharp
public class Vehicle : Unit
{
    [Header("Vehicle")]
    [SerializeField] private VehicleData vehicleData;
    [SerializeField] private Transform turret;
    [SerializeField] private float turretRotationSpeed = 90f;
    
    [Header("Transport")]
    [SerializeField] private Transform[] passengerSlots;
    private List<InfantrySquad> passengers = new();
    
    public bool CanTransport => vehicleData.transportCapacity > 0;
    public int RemainingCapacity => vehicleData.transportCapacity - passengers.Count;
    
    // Armor facing
    public float FrontArmor => vehicleData.frontArmor;
    public float SideArmor => vehicleData.sideArmor;
    public float RearArmor => vehicleData.rearArmor;
    
    protected override void UpdateCombat()
    {
        base.UpdateCombat();
        
        // Rotate turret toward target
        if (turret != null && CurrentTarget != null)
        {
            Vector3 direction = CurrentTarget.transform.position - turret.position;
            direction.y = 0;
            
            Quaternion targetRotation = Quaternion.LookRotation(direction);
            turret.rotation = Quaternion.RotateTowards(
                turret.rotation, targetRotation, turretRotationSpeed * Time.deltaTime);
        }
    }
    
    public bool LoadSquad(InfantrySquad squad)
    {
        if (!CanTransport || RemainingCapacity <= 0) return false;
        
        passengers.Add(squad);
        squad.gameObject.SetActive(false);
        
        // If this is an APC, it becomes a spawn point
        if (vehicleData.isSpawnPoint)
        {
            ProductionManager.Instance.RegisterSpawnPoint(this);
        }
        
        return true;
    }
    
    public void UnloadAll(Vector3 position)
    {
        foreach (var squad in passengers)
        {
            squad.gameObject.SetActive(true);
            squad.transform.position = position + Random.insideUnitSphere * 3f;
        }
        
        passengers.Clear();
    }
    
    public float GetArmorForAngle(Vector3 hitDirection)
    {
        float angle = Vector3.Angle(transform.forward, hitDirection);
        
        if (angle < 45f) return FrontArmor;
        if (angle > 135f) return RearArmor;
        return SideArmor;
    }
    
    public override void OnSelected()
    {
        base.OnSelected();
        
        // Show transport capacity if applicable
        if (CanTransport)
        {
            UIManager.Instance.ShowTransportInfo(this);
        }
    }
}
```

---

### 6. TERRITORY & CAPTURE SYSTEM

**Sector.cs:**

```csharp
public class Sector : MonoBehaviour
{
    [Header("Identity")]
    [SerializeField] private string sectorName;
    [SerializeField] private SectorType sectorType;
    
    [Header("Control")]
    [SerializeField] private CapturePoint capturePoint;
    [SerializeField] private Team controllingTeam;
    
    [Header("Resources")]
    [SerializeField] private int nanoPasteBonus = 10;
    [SerializeField] private int iskBonus = 15;
    
    [Header("Visuals")]
    [SerializeField] private MeshRenderer territoryHighlight;
    [SerializeField] private Color neutralColor = Color.gray;
    
    public Team ControllingTeam => controllingTeam;
    public bool IsNeutral => controllingTeam == null;
    public event System.Action<Sector, Team> OnControlChanged;
    
    void Start()
    {
        capturePoint.OnCaptured += HandleCapture;
        UpdateVisuals();
    }
    
    void HandleCapture(Team newOwner)
    {
        Team previousOwner = controllingTeam;
        controllingTeam = newOwner;
        
        // Update resources
        if (previousOwner != null)
        {
            ResourceManager.Instance.RemoveIncome(previousOwner, nanoPasteBonus, iskBonus);
        }
        
        if (newOwner != null)
        {
            ResourceManager.Instance.AddIncome(newOwner, nanoPasteBonus, iskBonus);
        }
        
        UpdateVisuals();
        OnControlChanged?.Invoke(this, newOwner);
    }
    
    void UpdateVisuals()
    {
        if (controllingTeam == null)
        {
            territoryHighlight.material.color = neutralColor;
        }
        else
        {
            territoryHighlight.material.color = controllingTeam.FactionColor;
        }
    }
}

public enum SectorType { Standard, FuelDepot, Uplink }
```

**CapturePoint.cs:**

```csharp
public class CapturePoint : MonoBehaviour
{
    [Header("Capture Settings")]
    [SerializeField] private float captureTime = 30f;
    [SerializeField] private float captureRadius = 10f;
    [SerializeField] private LayerMask captureLayer;
    
    private float captureProgress;
    private Team capturingTeam;
    private Team owningTeam;
    
    public float Progress => captureProgress;
    public Team OwningTeam => owningTeam;
    public bool IsContested { get; private set; }
    
    public event System.Action<Team> OnCaptured;
    
    void Update()
    {
        UpdateCapture();
    }
    
    void UpdateCapture()
    {
        // Count units in capture zone
        var colliders = Physics.OverlapSphere(transform.position, captureRadius, captureLayer);
        
        Dictionary<Team, int> teamCounts = new();
        
        foreach (var col in colliders)
        {
            if (col.TryGetComponent<Unit>(out var unit))
            {
                // Only infantry can capture
                if (unit is InfantrySquad squad && squad.IsAlive)
                {
                    if (!teamCounts.ContainsKey(unit.Team))
                        teamCounts[unit.Team] = 0;
                    teamCounts[unit.Team]++;
                }
            }
        }
        
        // Determine capture state
        if (teamCounts.Count == 0)
        {
            // No one here - progress decays
            IsContested = false;
            captureProgress = Mathf.MoveToward(captureProgress, 0f, Time.deltaTime / captureTime);
            if (captureProgress <= 0f) capturingTeam = null;
        }
        else if (teamCounts.Count == 1)
        {
            // One team present
            var team = teamCounts.Keys.First();
            IsContested = false;
            
            if (team == owningTeam)
            {
                // Owner reinforcing - reset progress
                captureProgress = Mathf.MoveToward(captureProgress, 0f, Time.deltaTime / captureTime);
            }
            else
            {
                // Enemy capturing
                if (capturingTeam != team)
                {
                    capturingTeam = team;
                    // If switching attackers, reset progress
                    if (captureProgress < 0) captureProgress = 0;
                }
                
                // Progress scales with unit count
                float speedMultiplier = Mathf.Min(teamCounts[team], 3); // Cap at 3x
                captureProgress += (Time.deltaTime / captureTime) * speedMultiplier;
                
                if (captureProgress >= 1f)
                {
                    CompleteCature(team);
                }
            }
        }
        else
        {
            // Contested - no progress
            IsContested = true;
        }
    }
    
    void CompleteCature(Team newOwner)
    {
        owningTeam = newOwner;
        captureProgress = 0f;
        capturingTeam = null;
        
        OnCaptured?.Invoke(newOwner);
    }
}
```

---

### 7. ORBITAL STRIKE SYSTEM

**OrbitalManager.cs:**

```csharp
public class OrbitalManager : MonoBehaviour
{
    public static OrbitalManager Instance { get; private set; }
    
    [Header("Configuration")]
    [SerializeField] private OrbitalStrikeData[] availableStrikes;
    
    private Dictionary<Team, List<UplinkStation>> teamUplinks = new();
    private Dictionary<Team, Dictionary<OrbitalStrikeData, float>> strikeCooldowns = new();
    
    public event System.Action<Team, OrbitalStrikeData> OnStrikeCalled;
    public event System.Action<Vector3, OrbitalStrikeData> OnStrikeImpact;
    
    public void RegisterUplink(UplinkStation uplink, Team team)
    {
        if (!teamUplinks.ContainsKey(team))
            teamUplinks[team] = new List<UplinkStation>();
        
        teamUplinks[team].Add(uplink);
    }
    
    public void UnregisterUplink(UplinkStation uplink, Team team)
    {
        if (teamUplinks.ContainsKey(team))
            teamUplinks[team].Remove(uplink);
    }
    
    public int GetUplinkCount(Team team)
    {
        return teamUplinks.ContainsKey(team) ? teamUplinks[team].Count : 0;
    }
    
    public bool CanCallStrike(Team team, OrbitalStrikeData strikeData)
    {
        // Must have at least one uplink
        if (GetUplinkCount(team) == 0) return false;
        
        // Check cooldown
        if (IsOnCooldown(team, strikeData)) return false;
        
        // Check resources
        if (!ResourceManager.Instance.CanAfford(team, 0, strikeData.iskCost)) return false;
        
        return true;
    }
    
    public float GetCooldownRemaining(Team team, OrbitalStrikeData strikeData)
    {
        if (!strikeCooldowns.ContainsKey(team)) return 0f;
        if (!strikeCooldowns[team].ContainsKey(strikeData)) return 0f;
        
        return Mathf.Max(0f, strikeCooldowns[team][strikeData] - Time.time);
    }
    
    public bool IsOnCooldown(Team team, OrbitalStrikeData strikeData)
    {
        return GetCooldownRemaining(team, strikeData) > 0f;
    }
    
    public float GetCooldownModifier(Team team)
    {
        int uplinks = GetUplinkCount(team);
        return uplinks switch
        {
            >= 3 => 0.6f,  // 40% faster cooldowns
            2 => 0.8f,     // 20% faster
            _ => 1f        // Normal
        };
    }
    
    public void RequestStrike(Team team, OrbitalStrikeData strikeData, Vector3 targetPosition)
    {
        if (!CanCallStrike(team, strikeData)) return;
        
        // Deduct cost
        ResourceManager.Instance.SpendResources(team, 0, strikeData.iskCost);
        
        // Start cooldown
        if (!strikeCooldowns.ContainsKey(team))
            strikeCooldowns[team] = new Dictionary<OrbitalStrikeData, float>();
        
        float cooldown = strikeData.cooldown * GetCooldownModifier(team);
        strikeCooldowns[team][strikeData] = Time.time + cooldown;
        
        // Start strike sequence
        StartCoroutine(ExecuteStrike(team, strikeData, targetPosition));
        
        OnStrikeCalled?.Invoke(team, strikeData);
    }
    
    IEnumerator ExecuteStrike(Team team, OrbitalStrikeData strikeData, Vector3 targetPosition)
    {
        // Show warning zone
        var warning = SpawnWarningIndicator(targetPosition, strikeData.radius);
        
        // Play incoming sound
        AudioManager.Instance.PlayStrikeIncoming(targetPosition);
        
        // Wait for delay
        yield return new WaitForSeconds(strikeData.delay);
        
        // Remove warning
        Destroy(warning);
        
        // Execute strike effect
        strikeData.ExecuteStrike(targetPosition, team);
        
        OnStrikeImpact?.Invoke(targetPosition, strikeData);
    }
}
```

**OrbitalStrikeData.cs:**

```csharp
[CreateAssetMenu(fileName = "Strike", menuName = "RTS/Orbital Strike")]
public class OrbitalStrikeData : ScriptableObject
{
    [Header("Identity")]
    public string strikeName;
    public string description;
    public Sprite icon;
    
    [Header("Targeting")]
    public float radius = 15f;
    public StrikeShape shape = StrikeShape.Circle;
    public float lineLength = 100f; // For line-shaped strikes
    
    [Header("Timing")]
    public float delay = 5f;
    public float cooldown = 60f;
    
    [Header("Cost")]
    public int iskCost = 200;
    
    [Header("Effect")]
    public int damage = 500;
    public bool damageVehicles = true;
    public bool damageInfantry = true;
    public bool disablesElectronics = false;
    public float disableDuration = 15f;
    
    [Header("Visuals")]
    public GameObject warningIndicatorPrefab;
    public GameObject impactEffectPrefab;
    public AudioClip impactSound;
    
    public virtual void ExecuteStrike(Vector3 position, Team sourceTeam)
    {
        // Spawn visual effect
        if (impactEffectPrefab != null)
        {
            Instantiate(impactEffectPrefab, position, Quaternion.identity);
        }
        
        // Play sound
        if (impactSound != null)
        {
            AudioSource.PlayClipAtPoint(impactSound, position);
        }
        
        // Apply damage
        var hits = Physics.OverlapSphere(position, radius);
        
        foreach (var hit in hits)
        {
            if (hit.TryGetComponent<Unit>(out var unit))
            {
                if (unit.Team == sourceTeam) continue; // No friendly fire
                
                // Check if this strike affects this unit type
                bool canDamage = (unit is Vehicle && damageVehicles) ||
                                  (unit is InfantrySquad && damageInfantry);
                
                if (canDamage)
                {
                    // Damage falloff from center
                    float distance = Vector3.Distance(position, unit.transform.position);
                    float falloff = 1f - (distance / radius);
                    int finalDamage = Mathf.RoundToInt(damage * falloff);
                    
                    unit.TakeDamage(finalDamage, DamageType.Explosive);
                }
                
                // EMP effect
                if (disablesElectronics && unit is Vehicle vehicle)
                {
                    vehicle.Disable(disableDuration);
                }
            }
        }
    }
}

public enum StrikeShape { Circle, Line }
```

---

### 8. ECONOMY & PRODUCTION

**ResourceManager.cs:**

```csharp
public class ResourceManager : MonoBehaviour
{
    public static ResourceManager Instance { get; private set; }
    
    [Header("Starting Resources")]
    [SerializeField] private int startingNanoPaste = 500;
    [SerializeField] private int startingISK = 300;
    
    [Header("Base Income")]
    [SerializeField] private int baseNanoPastePerMinute = 50;
    [SerializeField] private int baseISKPerMinute = 20;
    
    [Header("Caps")]
    [SerializeField] private int maxNanoPaste = 1000;
    [SerializeField] private int maxISK = 2000;
    
    private Dictionary<Team, ResourceState> teamResources = new();
    
    public event System.Action<Team, int, int> OnResourcesChanged;
    
    public void InitializeTeam(Team team)
    {
        teamResources[team] = new ResourceState
        {
            nanoPaste = startingNanoPaste,
            isk = startingISK,
            nanoPasteIncome = baseNanoPastePerMinute,
            iskIncome = baseISKPerMinute
        };
    }
    
    void Update()
    {
        // Generate income
        foreach (var kvp in teamResources)
        {
            var team = kvp.Key;
            var state = kvp.Value;
            
            // Per-second income (divide by 60)
            state.nanoPaste += (state.nanoPasteIncome / 60f) * Time.deltaTime;
            state.isk += (state.iskIncome / 60f) * Time.deltaTime;
            
            // Cap
            state.nanoPaste = Mathf.Min(state.nanoPaste, maxNanoPaste);
            state.isk = Mathf.Min(state.isk, maxISK);
            
            teamResources[team] = state;
        }
    }
    
    public int GetNanoPaste(Team team) => Mathf.FloorToInt(teamResources[team].nanoPaste);
    public int GetISK(Team team) => Mathf.FloorToInt(teamResources[team].isk);
    
    public bool CanAfford(Team team, int nanoPaste, int isk)
    {
        var state = teamResources[team];
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
    
    public void AddIncome(Team team, int nanoPasteBonus, int iskBonus)
    {
        var state = teamResources[team];
        state.nanoPasteIncome += nanoPasteBonus;
        state.iskIncome += iskBonus;
        teamResources[team] = state;
    }
    
    public void RemoveIncome(Team team, int nanoPasteBonus, int iskBonus)
    {
        var state = teamResources[team];
        state.nanoPasteIncome -= nanoPasteBonus;
        state.iskIncome -= iskBonus;
        teamResources[team] = state;
    }
    
    public void AddKillBounty(Team team, Unit killedUnit)
    {
        int bounty = killedUnit.Data.iskCost / 10; // 10% of unit cost
        var state = teamResources[team];
        state.isk += bounty;
        teamResources[team] = state;
        
        OnResourcesChanged?.Invoke(team, GetNanoPaste(team), GetISK(team));
    }
    
    private struct ResourceState
    {
        public float nanoPaste;
        public float isk;
        public float nanoPasteIncome;
        public float iskIncome;
    }
}
```

**ProductionManager.cs:**

```csharp
public class ProductionManager : MonoBehaviour
{
    public static ProductionManager Instance { get; private set; }
    
    [Header("Configuration")]
    [SerializeField] private int maxQueueSize = 5;
    
    private Dictionary<Team, ProductionQueue> teamQueues = new();
    private Dictionary<Team, List<Transform>> spawnPoints = new();
    
    public event System.Action<Team, UnitData> OnProductionStarted;
    public event System.Action<Team, Unit> OnUnitProduced;
    
    public void InitializeTeam(Team team, Transform defaultSpawnPoint)
    {
        teamQueues[team] = new ProductionQueue(maxQueueSize);
        spawnPoints[team] = new List<Transform> { defaultSpawnPoint };
    }
    
    public void RegisterSpawnPoint(Vehicle apc)
    {
        var team = apc.Team;
        if (!spawnPoints.ContainsKey(team)) return;
        
        spawnPoints[team].Add(apc.transform);
        
        apc.OnKilled += _ => spawnPoints[team].Remove(apc.transform);
    }
    
    public bool QueueUnit(Team team, UnitData unitData)
    {
        if (!teamQueues.ContainsKey(team)) return false;
        
        var queue = teamQueues[team];
        if (queue.IsFull) return false;
        
        // Check cost
        if (!ResourceManager.Instance.CanAfford(team, unitData.nanoPasteCost, unitData.iskCost))
            return false;
        
        // Spend resources
        ResourceManager.Instance.SpendResources(team, unitData.nanoPasteCost, unitData.iskCost);
        
        // Add to queue
        queue.Add(new ProductionItem(unitData));
        
        OnProductionStarted?.Invoke(team, unitData);
        return true;
    }
    
    public bool CancelProduction(Team team, int index)
    {
        if (!teamQueues.ContainsKey(team)) return false;
        
        var queue = teamQueues[team];
        var item = queue.GetItem(index);
        
        if (item == null) return false;
        
        // Refund partial cost based on progress
        float refundPercent = 1f - item.Progress;
        int nanoPasteRefund = Mathf.RoundToInt(item.UnitData.nanoPasteCost * refundPercent * 0.75f);
        int iskRefund = Mathf.RoundToInt(item.UnitData.iskCost * refundPercent * 0.75f);
        
        ResourceManager.Instance.AddResources(team, nanoPasteRefund, iskRefund);
        
        queue.Remove(index);
        return true;
    }
    
    void Update()
    {
        foreach (var kvp in teamQueues)
        {
            var team = kvp.Key;
            var queue = kvp.Value;
            
            // Process all items in parallel
            foreach (var item in queue.Items)
            {
                item.Progress += Time.deltaTime / item.UnitData.buildTime;
                
                if (item.Progress >= 1f)
                {
                    CompleteProduction(team, item);
                    queue.RemoveCompleted(item);
                }
            }
        }
    }
    
    void CompleteProduction(Team team, ProductionItem item)
    {
        // Find best spawn point
        Transform spawnPoint = GetBestSpawnPoint(team);
        
        // Instantiate unit
        var unitPrefab = item.UnitData.prefab;
        var unitGO = Instantiate(unitPrefab, spawnPoint.position, spawnPoint.rotation);
        var unit = unitGO.GetComponent<Unit>();
        
        unit.Initialize(team);
        UnitManager.Instance.RegisterUnit(unit);
        
        OnUnitProduced?.Invoke(team, unit);
    }
    
    Transform GetBestSpawnPoint(Team team)
    {
        // Prefer forward spawn points (APCs) over base
        var points = spawnPoints[team];
        
        // Simple: return closest to center of map
        // Better: return closest to current objectives
        return points.OrderBy(p => Vector3.Distance(p.position, Vector3.zero)).First();
    }
    
    public List<ProductionItem> GetQueue(Team team)
    {
        return teamQueues.ContainsKey(team) ? teamQueues[team].Items : new List<ProductionItem>();
    }
}

public class ProductionItem
{
    public UnitData UnitData { get; }
    public float Progress { get; set; }
    
    public ProductionItem(UnitData data)
    {
        UnitData = data;
        Progress = 0f;
    }
}

public class ProductionQueue
{
    private List<ProductionItem> items = new();
    private int maxSize;
    
    public List<ProductionItem> Items => items;
    public bool IsFull => items.Count >= maxSize;
    
    public ProductionQueue(int maxSize) { this.maxSize = maxSize; }
    
    public void Add(ProductionItem item) { if (!IsFull) items.Add(item); }
    public void Remove(int index) { if (index < items.Count) items.RemoveAt(index); }
    public void RemoveCompleted(ProductionItem item) { items.Remove(item); }
    public ProductionItem GetItem(int index) => index < items.Count ? items[index] : null;
}
```

---

### 9. COMBAT & DAMAGE SYSTEM

**DamageSystem.cs:**

```csharp
public static class DamageSystem
{
    public static void ApplyDamage(Unit target, int baseDamage, DamageType type, 
        Vector3 hitDirection, Unit source = null)
    {
        float finalDamage = baseDamage;
        
        // Armor calculation
        float armor = target.Data.armor;
        
        // Vehicle facing armor
        if (target is Vehicle vehicle)
        {
            armor = vehicle.GetArmorForAngle(hitDirection);
        }
        
        // Armor reduction (diminishing returns)
        float armorReduction = armor / (armor + 100f); // 50 armor = 33% reduction
        finalDamage *= (1f - armorReduction);
        
        // Cover reduction (infantry only)
        if (target is InfantrySquad squad)
        {
            finalDamage *= (1f - squad.GetDamageReduction());
        }
        
        // Damage type modifiers
        finalDamage *= GetDamageTypeModifier(type, target);
        
        // Veterancy modifier (takes less damage when experienced)
        finalDamage /= target.GetVeterancyModifier();
        
        // Apply damage
        int finalDamageInt = Mathf.RoundToInt(finalDamage);
        target.TakeDamage(finalDamageInt, type);
        
        // Credit kill if lethal
        if (!target.IsAlive && source != null)
        {
            source.RegisterKill();
            ResourceManager.Instance.AddKillBounty(source.Team, target);
        }
    }
    
    static float GetDamageTypeModifier(DamageType type, Unit target)
    {
        // AP good vs armor, HE good vs infantry
        return (type, target) switch
        {
            (DamageType.ArmorPiercing, Vehicle _) => 1.5f,
            (DamageType.ArmorPiercing, InfantrySquad _) => 0.75f,
            (DamageType.HighExplosive, InfantrySquad _) => 1.25f,
            (DamageType.HighExplosive, Vehicle _) => 0.75f,
            _ => 1f
        };
    }
}

public enum DamageType
{
    Kinetic,        // Standard bullets
    ArmorPiercing,  // AT weapons
    HighExplosive,  // Grenades, artillery
    Energy,         // Lasers
    EMP             // Disables, no damage
}
```

**Weapon.cs:**

```csharp
public class Weapon : MonoBehaviour
{
    [SerializeField] private WeaponData data;
    [SerializeField] private Transform muzzle;
    
    private float lastFireTime;
    private int currentAmmo;
    private bool isReloading;
    
    public WeaponData Data => data;
    public bool CanFire() => !isReloading && Time.time >= lastFireTime + (1f / data.fireRate);
    
    void Awake()
    {
        currentAmmo = data.magazineSize;
    }
    
    public void Fire(Unit target)
    {
        if (!CanFire()) return;
        
        lastFireTime = Time.time;
        currentAmmo--;
        
        if (data.isHitscan)
        {
            FireHitscan(target);
        }
        else
        {
            FireProjectile(target);
        }
        
        // Effects
        SpawnMuzzleFlash();
        PlayFireSound();
        
        // Reload check
        if (currentAmmo <= 0)
        {
            StartCoroutine(Reload());
        }
    }
    
    void FireHitscan(Unit target)
    {
        Vector3 direction = (target.transform.position - muzzle.position).normalized;
        
        // Apply spread
        direction = ApplySpread(direction, data.spread);
        
        if (Physics.Raycast(muzzle.position, direction, out RaycastHit hit, data.range))
        {
            // Spawn impact effect
            SpawnImpact(hit.point, hit.normal);
            
            // Apply damage
            if (hit.collider.TryGetComponent<Unit>(out var hitUnit))
            {
                DamageSystem.ApplyDamage(
                    hitUnit, 
                    data.damage, 
                    data.damageType, 
                    direction,
                    GetComponentInParent<Unit>()
                );
            }
        }
    }
    
    void FireProjectile(Unit target)
    {
        Vector3 direction = (target.transform.position - muzzle.position).normalized;
        direction = ApplySpread(direction, data.spread);
        
        var projectile = ObjectPool.Instance.Get<Projectile>(data.projectilePrefab);
        projectile.transform.position = muzzle.position;
        projectile.transform.rotation = Quaternion.LookRotation(direction);
        projectile.Initialize(data, GetComponentInParent<Unit>());
    }
    
    Vector3 ApplySpread(Vector3 direction, float spread)
    {
        float spreadRad = spread * Mathf.Deg2Rad;
        return Quaternion.Euler(
            Random.Range(-spreadRad, spreadRad) * Mathf.Rad2Deg,
            Random.Range(-spreadRad, spreadRad) * Mathf.Rad2Deg,
            0
        ) * direction;
    }
    
    IEnumerator Reload()
    {
        isReloading = true;
        yield return new WaitForSeconds(data.reloadTime);
        currentAmmo = data.magazineSize;
        isReloading = false;
    }
}
```

---

## IMPLEMENTATION ORDER

### Phase 1: Foundation (Weeks 1-2)

**Days 1-3: Project Setup**
- Create Unity project with folder structure
- Set up Input System
- Create test scene with terrain

**Days 4-6: Camera System**
- WASD pan + edge scroll + middle mouse drag
- Zoom with scroll wheel
- Camera bounds
- Minimap camera

**Days 7-10: Selection System**
- Click to select
- Box select
- Control groups
- Basic unit prefab (cube placeholder)

**Days 11-14: Basic Movement**
- Unit base class
- NavMesh pathfinding
- Move commands
- Formation movement basics

### Phase 2: Combat (Weeks 3-4)

**Days 15-18: Units**
- Infantry squad implementation
- Vehicle implementation
- Health and damage
- Death handling

**Days 19-22: Weapons**
- Weapon data system
- Hitscan weapons
- Projectile weapons
- Reload system

**Days 23-26: Cover & Suppression**
- Cover points
- Cover detection
- Damage reduction
- Suppression state
- Garrison system

**Days 27-28: Combat Polish**
- Auto-targeting
- Attack-move
- Unit veterancy
- Combat feedback (hit effects, sounds)

### Phase 3: Territory (Weeks 5-6)

**Days 29-32: Sectors**
- Sector system
- Capture points
- Territory control visualization
- Victory point tracking

**Days 33-36: Economy**
- Resource manager
- Income from territory
- Kill bounties
- Resource UI

**Days 37-40: Production**
- Production queue
- Unit spawning
- Spawn points
- Production UI

### Phase 4: Orbital (Weeks 7-8)

**Days 41-44: Uplinks**
- Uplink stations
- Capture mechanics
- Orbital manager
- Strike cooldowns

**Days 45-48: Strikes**
- Precision strike
- Bombardment
- EMP strike
- Strike visuals and effects

**Days 49-52: Orbital Polish**
- Warning indicators
- Strike targeting UI
- Camera shake
- Audio

### Phase 5: AI & Polish (Weeks 9-10)

**Days 53-56: Unit AI**
- Idle behavior
- Combat behavior
- Cover seeking
- Attack prioritization

**Days 57-60: Commander AI**
- Build orders
- Resource management
- Territory strategy
- Attack coordination

**Days 61-64: Balance & Polish**
- Unit balancing
- Economic balancing
- UI polish
- Audio implementation

### Phase 6: Content (Weeks 11-12)

**Days 65-68: Factions**
- Faction data structure
- Visual differentiation
- Unique units (1-2 per faction)

**Days 69-72: Maps**
- Second map
- Map selection
- Skirmish setup screen

**Days 73-76: Final Polish**
- Main menu
- Settings
- Bug fixes
- Performance optimization

---

## SUCCESS CRITERIA

The prototype is successful when:

1. **Core Loop Works:** Select units → Issue commands → Watch them fight → Capture territory → Win/lose
2. **Combined Arms:** Infantry, vehicles, and orbital strikes all feel useful and distinct
3. **Territory Matters:** Controlling map = controlling resources = winning
4. **Orbital is Dramatic:** Calling in strikes feels powerful and game-changing
5. **AI Provides Challenge:** Skirmish vs AI is engaging for 15-20 minute matches
6. **Performance:** 100+ units on screen at 60 FPS

---

## BEGIN IMPLEMENTATION

Start with Phase 1, Day 1. Create the project structure and camera system.

Build systematically. Test after each system. The goal is a playable skirmish match against AI that captures the DUST fantasy of planetary warfare.

When in doubt, ask: "Does this make me feel like a commander directing a war?"

Good luck, Commander.

---

*DUST Orbital Command RTS — Build Prompt v1.0*
