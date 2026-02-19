using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Selection;
using DustRTS.Territory;
using DustRTS.Utility;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// Base class for all units in the game.
    /// Handles common functionality like movement, combat, and veterancy.
    /// </summary>
    [RequireComponent(typeof(Selectable))]
    [RequireComponent(typeof(UnitHealth))]
    [RequireComponent(typeof(UnitMovement))]
    public class Unit : MonoBehaviour
    {
        [Header("Data")]
        [SerializeField] protected UnitData unitData;

        [Header("Components")]
        [SerializeField] protected Selectable selectable;
        [SerializeField] protected UnitHealth health;
        [SerializeField] protected UnitMovement movement;

        [Header("Combat")]
        [SerializeField] protected Transform weaponMuzzle;

        // State
        protected Team team;
        protected Unit currentTarget;
        protected UnitState currentState = UnitState.Idle;
        protected Queue<UnitCommand> commandQueue = new();

        // Veterancy
        protected int killCount;
        protected VeterancyLevel veterancy = VeterancyLevel.Rookie;

        // Combat
        protected float lastAttackTime;
        protected bool isInCombat;

        // Properties
        public UnitData Data => unitData;
        public Team Team => team;
        public bool IsAlive => health.IsAlive;
        public bool IsSelected => selectable.IsSelected;
        public Unit CurrentTarget => currentTarget;
        public UnitState CurrentState => currentState;
        public int KillCount => killCount;
        public VeterancyLevel Veterancy => veterancy;
        public bool IsInCombat => isInCombat;
        public float HealthPercent => health.HealthPercent;

        // Events
        public event Action<Unit> OnKilled;
        public event Action<Unit> OnTargetAcquired;
        public event Action OnStateChanged;

        protected virtual void Awake()
        {
            if (selectable == null) selectable = GetComponent<Selectable>();
            if (health == null) health = GetComponent<UnitHealth>();
            if (movement == null) movement = GetComponent<UnitMovement>();

            health.OnDeath += HandleDeath;
            movement.OnDestinationReached += OnDestinationReached;
        }

        public virtual void Initialize(Team team)
        {
            this.team = team;

            selectable.Initialize(team);
            health.Initialize(unitData);
            movement.Initialize(unitData);

            UnitManager.Instance?.RegisterUnit(this);
        }

        protected virtual void Update()
        {
            if (!IsAlive) return;

            UpdateState();
            UpdateCombat();
        }

        protected virtual void UpdateState()
        {
            switch (currentState)
            {
                case UnitState.Idle:
                    UpdateIdleState();
                    break;
                case UnitState.Moving:
                    UpdateMovingState();
                    break;
                case UnitState.Attacking:
                    UpdateAttackingState();
                    break;
                case UnitState.Capturing:
                    UpdateCapturingState();
                    break;
                case UnitState.Following:
                    UpdateFollowingState();
                    break;
            }
        }

        protected virtual void UpdateIdleState()
        {
            // Auto-acquire nearby enemies
            if (currentTarget == null || !currentTarget.IsAlive)
            {
                currentTarget = FindNearestEnemy();
                if (currentTarget != null)
                {
                    OnTargetAcquired?.Invoke(currentTarget);
                }
            }
        }

        protected virtual void UpdateMovingState()
        {
            if (!movement.IsMoving)
            {
                ProcessNextCommand();
            }
        }

        protected virtual void UpdateAttackingState()
        {
            if (currentTarget == null || !currentTarget.IsAlive)
            {
                currentTarget = FindNearestEnemy();
                if (currentTarget == null)
                {
                    SetState(UnitState.Idle);
                    return;
                }
            }

            float distance = Vector3.Distance(transform.position, currentTarget.transform.position);
            float range = unitData.primaryWeapon?.weapon?.range ?? 10f;

            if (distance > range)
            {
                // Move toward target
                Vector3 direction = (currentTarget.transform.position - transform.position).normalized;
                Vector3 attackPosition = currentTarget.transform.position - direction * (range * 0.8f);
                movement.SetDestination(attackPosition);
            }
            else
            {
                // In range - stop and attack
                movement.Stop();
                TryAttack();
            }
        }

        protected virtual void UpdateCapturingState()
        {
            // Override in infantry
        }

        protected virtual void UpdateFollowingState()
        {
            if (currentTarget == null || !currentTarget.IsAlive)
            {
                SetState(UnitState.Idle);
                return;
            }

            float distance = Vector3.Distance(transform.position, currentTarget.transform.position);
            if (distance > 5f)
            {
                movement.SetDestination(currentTarget.transform.position);
            }
        }

        protected virtual void UpdateCombat()
        {
            // Clear dead target
            if (currentTarget != null && !currentTarget.IsAlive)
            {
                currentTarget = null;
            }

            isInCombat = currentTarget != null;
        }

        protected virtual void TryAttack()
        {
            if (currentTarget == null) return;
            if (unitData.primaryWeapon?.weapon == null) return;

            var weaponData = unitData.primaryWeapon.weapon;
            float timeSinceLastAttack = Time.time - lastAttackTime;

            if (timeSinceLastAttack >= weaponData.FireInterval)
            {
                // Face target
                movement.RotateTowards(currentTarget.transform.position);

                if (movement.IsLookingAt(currentTarget.transform.position, 15f))
                {
                    Fire(currentTarget);
                    lastAttackTime = Time.time;
                }
            }
        }

        protected virtual void Fire(Unit target)
        {
            if (unitData.primaryWeapon?.weapon == null) return;

            var weaponData = unitData.primaryWeapon.weapon;
            int damage = weaponData.GetDamage();

            // Apply veterancy bonus
            damage = Mathf.RoundToInt(damage * GetVeterancyModifier());

            // Apply damage
            Vector3 hitDirection = (target.transform.position - transform.position).normalized;
            target.TakeDamage(damage, weaponData.damageType, hitDirection, this);

            // TODO: Spawn muzzle flash, tracer, impact effects
        }

        public void TakeDamage(int amount, DamageType type, Vector3 direction, Unit source = null)
        {
            health.TakeDamage(amount, type, direction);

            // If we're idle and attacked, target the attacker
            if (currentState == UnitState.Idle && source != null && source.Team.IsEnemy(team))
            {
                currentTarget = source;
                SetState(UnitState.Attacking);
            }
        }

        protected Unit FindNearestEnemy()
        {
            var manager = UnitManager.Instance;
            if (manager == null) return null;

            var enemies = manager.GetEnemyUnits(team);
            return enemies
                .Where(e => e != null && e.IsAlive)
                .Where(e => Vector3.Distance(transform.position, e.transform.position) <= unitData.sightRange)
                .OrderBy(e => Vector3.Distance(transform.position, e.transform.position))
                .FirstOrDefault();
        }

        // Commands
        public virtual void MoveTo(Vector3 position, bool queue = false)
        {
            var command = new UnitCommand(CommandType.Move, position);

            if (queue)
            {
                commandQueue.Enqueue(command);
            }
            else
            {
                ClearCommands();
                ExecuteCommand(command);
            }
        }

        public virtual void AttackTarget(Unit target, bool queue = false)
        {
            if (target == null) return;

            var command = new UnitCommand(CommandType.Attack, target);

            if (queue)
            {
                commandQueue.Enqueue(command);
            }
            else
            {
                ClearCommands();
                ExecuteCommand(command);
            }
        }

        public virtual void AttackMove(Vector3 position, bool queue = false)
        {
            var command = new UnitCommand(CommandType.AttackMove, position);

            if (queue)
            {
                commandQueue.Enqueue(command);
            }
            else
            {
                ClearCommands();
                ExecuteCommand(command);
            }
        }

        public virtual void Follow(Unit target, bool queue = false)
        {
            if (target == null) return;

            var command = new UnitCommand(CommandType.Follow, target);

            if (queue)
            {
                commandQueue.Enqueue(command);
            }
            else
            {
                ClearCommands();
                ExecuteCommand(command);
            }
        }

        public virtual void Capture(CapturePoint point, bool queue = false)
        {
            var command = new UnitCommand(CommandType.Capture, point);

            if (queue)
            {
                commandQueue.Enqueue(command);
            }
            else
            {
                ClearCommands();
                ExecuteCommand(command);
            }
        }

        public virtual void Stop()
        {
            ClearCommands();
            movement.Stop();
            currentTarget = null;
            SetState(UnitState.Idle);
        }

        public virtual void HoldPosition()
        {
            ClearCommands();
            movement.Stop();
            // Will still engage targets but won't move
        }

        protected void ExecuteCommand(UnitCommand command)
        {
            switch (command.Type)
            {
                case CommandType.Move:
                    movement.SetDestination(command.Position);
                    SetState(UnitState.Moving);
                    break;

                case CommandType.Attack:
                    currentTarget = command.TargetUnit;
                    SetState(UnitState.Attacking);
                    OnTargetAcquired?.Invoke(currentTarget);
                    break;

                case CommandType.AttackMove:
                    movement.SetDestination(command.Position);
                    SetState(UnitState.Moving);
                    // Will auto-engage enemies while moving
                    break;

                case CommandType.Follow:
                    currentTarget = command.TargetUnit;
                    SetState(UnitState.Following);
                    break;

                case CommandType.Capture:
                    if (unitData.canCapture && command.CapturePoint != null)
                    {
                        movement.SetDestination(command.CapturePoint.transform.position);
                        SetState(UnitState.Capturing);
                    }
                    break;
            }
        }

        protected void ProcessNextCommand()
        {
            if (commandQueue.Count > 0)
            {
                var command = commandQueue.Dequeue();
                ExecuteCommand(command);
            }
            else
            {
                SetState(UnitState.Idle);
            }
        }

        protected void ClearCommands()
        {
            commandQueue.Clear();
        }

        protected void OnDestinationReached()
        {
            ProcessNextCommand();
        }

        protected void SetState(UnitState newState)
        {
            if (currentState == newState) return;

            currentState = newState;
            OnStateChanged?.Invoke();
        }

        // Veterancy
        public void RegisterKill()
        {
            killCount++;
            UpdateVeterancy();
        }

        protected void UpdateVeterancy()
        {
            veterancy = killCount switch
            {
                >= 30 => VeterancyLevel.Elite,
                >= 15 => VeterancyLevel.Veteran,
                >= 5 => VeterancyLevel.Experienced,
                _ => VeterancyLevel.Rookie
            };
        }

        public float GetVeterancyModifier()
        {
            return veterancy switch
            {
                VeterancyLevel.Elite => 1.3f,
                VeterancyLevel.Veteran => 1.2f,
                VeterancyLevel.Experienced => 1.1f,
                _ => 1f
            };
        }

        protected virtual void HandleDeath()
        {
            UnitManager.Instance?.UnregisterUnit(this);
            OnKilled?.Invoke(this);

            // Credit kill to attacker
            // TODO: Track last attacker

            // Play death effects
            // TODO: Spawn death effect, play sound

            // Destroy after delay
            Destroy(gameObject, 2f);
        }

        protected virtual void OnDestroy()
        {
            health.OnDeath -= HandleDeath;
            movement.OnDestinationReached -= OnDestinationReached;
        }
    }

    public enum UnitState
    {
        Idle,
        Moving,
        Attacking,
        Capturing,
        Following,
        Garrisoned,
        Disabled
    }

    public enum VeterancyLevel
    {
        Rookie,
        Experienced,
        Veteran,
        Elite
    }

    public struct UnitCommand
    {
        public CommandType Type;
        public Vector3 Position;
        public Unit TargetUnit;
        public CapturePoint CapturePoint;

        public UnitCommand(CommandType type, Vector3 position)
        {
            Type = type;
            Position = position;
            TargetUnit = null;
            CapturePoint = null;
        }

        public UnitCommand(CommandType type, Unit target)
        {
            Type = type;
            Position = target.transform.position;
            TargetUnit = target;
            CapturePoint = null;
        }

        public UnitCommand(CommandType type, CapturePoint point)
        {
            Type = type;
            Position = point.transform.position;
            TargetUnit = null;
            CapturePoint = point;
        }
    }

    public enum CommandType
    {
        Move,
        Attack,
        AttackMove,
        Follow,
        Capture,
        Garrison,
        Repair,
        UseAbility
    }
}
