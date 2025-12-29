using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss.HitotsumeKozo
{
    /// <summary>
    /// Hitotsume-Kozo: The one-eyed boy yokai.
    /// Tier 1 teaching boss - chase and controlled aggression.
    ///
    /// Core mechanic: Pressure timer that punishes passivity.
    /// If player doesn't deal damage within time limit, boss regenerates.
    /// Boss flees and taunts, must be chased down.
    ///
    /// Proverb: "The timid are never caught, but they are never finished."
    /// </summary>
    public class HitotsumeKozoBoss : MonoBehaviour
    {
        [Header("Attacks")]
        [SerializeField] private AttackDefinition _panicSwipeAttack;

        [Header("Timing")]
        [SerializeField] private float _fleeDuration = 2f;
        [SerializeField] private float _tauntDuration = 1f;
        [SerializeField] private float _corneredDuration = 0.5f;
        [SerializeField] private float _regenerateDuration = 1.5f;
        [SerializeField] private float _staggerDuration = 1.2f;

        [Header("Pressure System")]
        [Tooltip("Time without taking damage before boss regenerates")]
        [SerializeField] private float _pressureTimeout = 5f;
        [Tooltip("HP restored when regenerating")]
        [SerializeField] private int _regenAmount = 1;

        [Header("Behavior")]
        [Tooltip("Chance to taunt instead of continuing to flee")]
        [SerializeField] [Range(0f, 1f)] private float _tauntChance = 0.3f;
        [SerializeField] private int _healthPoints = 3;
        [SerializeField] private int _maxHealthPoints = 3;

        private HitotsumeKozoState _state = HitotsumeKozoState.Inactive;
        private float _stateTimer;
        private float _pressureTimer;
        private int _currentHealth;
        private int _fleeCount;
        private AttackRunner _attackRunner;

        public HitotsumeKozoState State => _state;
        public int CurrentHealth => _currentHealth;
        public int MaxHealth => _maxHealthPoints;
        public float PressureTimer => _pressureTimer;
        public float PressureTimeout => _pressureTimeout;
        public bool IsPressured => _pressureTimer < _pressureTimeout;

        public event Action<HitotsumeKozoState> OnStateChanged;
        public event Action OnFlee;
        public event Action OnTaunt;
        public event Action<int> OnRegenerate; // HP restored
        public event Action OnDefeated;
        public event Action OnPressureWarning; // Fires when close to regenerating

        private void Awake()
        {
            _attackRunner = GetComponent<AttackRunner>();
            if (_attackRunner == null)
                _attackRunner = gameObject.AddComponent<AttackRunner>();

            _attackRunner.OnAttackEnded += OnAttackEnded;
            _currentHealth = _healthPoints;
        }

        private void OnDestroy()
        {
            if (_attackRunner != null)
                _attackRunner.OnAttackEnded -= OnAttackEnded;
        }

        public void StartEncounter()
        {
            _currentHealth = _healthPoints;
            _pressureTimer = 0f;
            _fleeCount = 0;
            TransitionTo(HitotsumeKozoState.Intro);
        }

        private void FixedUpdate()
        {
            if (_state == HitotsumeKozoState.Inactive || _state == HitotsumeKozoState.Defeated)
                return;

            _stateTimer += Time.fixedDeltaTime;

            // Pressure timer always ticks (except during regen/stagger)
            if (_state != HitotsumeKozoState.Regenerate &&
                _state != HitotsumeKozoState.Staggered &&
                _state != HitotsumeKozoState.Intro)
            {
                _pressureTimer += Time.fixedDeltaTime;

                // Warning at 80% of timeout
                if (_pressureTimer >= _pressureTimeout * 0.8f &&
                    _pressureTimer < _pressureTimeout * 0.8f + Time.fixedDeltaTime)
                {
                    OnPressureWarning?.Invoke();
                }

                // Trigger regeneration if pressure times out
                if (_pressureTimer >= _pressureTimeout && _currentHealth < _maxHealthPoints)
                {
                    TransitionTo(HitotsumeKozoState.Regenerate);
                    return;
                }
            }

            switch (_state)
            {
                case HitotsumeKozoState.Intro:
                    if (_stateTimer >= 1f)
                    {
                        TransitionTo(HitotsumeKozoState.Flee);
                    }
                    break;

                case HitotsumeKozoState.Flee:
                    if (_stateTimer >= _fleeDuration)
                    {
                        // Chance to taunt, increases with flee count
                        float adjustedTauntChance = _tauntChance + (_fleeCount * 0.1f);
                        if (UnityEngine.Random.value < adjustedTauntChance)
                        {
                            TransitionTo(HitotsumeKozoState.Taunt);
                        }
                        else
                        {
                            // Continue fleeing
                            _stateTimer = 0f;
                            _fleeCount++;
                            OnFlee?.Invoke();
                        }
                    }
                    break;

                case HitotsumeKozoState.Taunt:
                    if (_stateTimer >= _tauntDuration)
                    {
                        TransitionTo(HitotsumeKozoState.Flee);
                    }
                    break;

                case HitotsumeKozoState.Cornered:
                    if (_stateTimer >= _corneredDuration)
                    {
                        TransitionTo(HitotsumeKozoState.PanicSwipe);
                    }
                    break;

                case HitotsumeKozoState.Regenerate:
                    if (_stateTimer >= _regenerateDuration)
                    {
                        // Heal and resume fleeing
                        int healed = Mathf.Min(_regenAmount, _maxHealthPoints - _currentHealth);
                        _currentHealth += healed;
                        OnRegenerate?.Invoke(healed);
                        _pressureTimer = 0f;
                        TransitionTo(HitotsumeKozoState.Flee);
                    }
                    break;

                case HitotsumeKozoState.Staggered:
                    if (_stateTimer >= _staggerDuration)
                    {
                        TransitionTo(HitotsumeKozoState.Flee);
                    }
                    break;
            }
        }

        private void TransitionTo(HitotsumeKozoState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;

            switch (newState)
            {
                case HitotsumeKozoState.Flee:
                    _fleeCount = 0;
                    OnFlee?.Invoke();
                    break;

                case HitotsumeKozoState.Taunt:
                    OnTaunt?.Invoke();
                    break;

                case HitotsumeKozoState.PanicSwipe:
                    _attackRunner.Execute(_panicSwipeAttack, transform);
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == HitotsumeKozoState.PanicSwipe)
            {
                // After panic attack, flee again
                TransitionTo(HitotsumeKozoState.Flee);
            }
        }

        /// <summary>
        /// Called when player catches up to the boss during Flee or Taunt.
        /// </summary>
        public void NotifyPlayerCaughtUp()
        {
            if (_state == HitotsumeKozoState.Flee || _state == HitotsumeKozoState.Taunt)
            {
                TransitionTo(HitotsumeKozoState.Cornered);
            }
        }

        /// <summary>
        /// Called when player lands an attack during Taunt state.
        /// Resets pressure timer.
        /// </summary>
        public void NotifyPlayerAttacked()
        {
            _pressureTimer = 0f;
        }

        public void ApplyStagger(float duration)
        {
            _staggerDuration = duration;
            _attackRunner.Cancel();
            _pressureTimer = 0f; // Reset pressure on stagger
            TransitionTo(HitotsumeKozoState.Staggered);
        }

        public void TakeDamage()
        {
            _currentHealth--;
            _pressureTimer = 0f; // Reset pressure timer on damage

            if (_currentHealth <= 0)
            {
                Defeat();
            }
            else
            {
                TransitionTo(HitotsumeKozoState.Flee);
            }
        }

        public void Defeat()
        {
            _attackRunner.Cancel();
            TransitionTo(HitotsumeKozoState.Defeated);
            OnDefeated?.Invoke();
        }

        /// <summary>
        /// Boss is vulnerable when staggered or taunting.
        /// </summary>
        public bool IsVulnerable => _state == HitotsumeKozoState.Staggered;

        /// <summary>
        /// Boss can be directly attacked during taunt (doesn't require stagger).
        /// </summary>
        public bool IsOpenToAttack => _state == HitotsumeKozoState.Taunt ||
                                       _state == HitotsumeKozoState.Staggered;

        /// <summary>
        /// Returns true if boss is about to regenerate (pressure warning).
        /// </summary>
        public bool IsAboutToRegenerate => _pressureTimer >= _pressureTimeout * 0.8f;
    }
}
