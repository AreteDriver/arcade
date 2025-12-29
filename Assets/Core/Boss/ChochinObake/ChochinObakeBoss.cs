using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss.ChochinObake
{
    /// <summary>
    /// Chochin-Obake: The lantern yokai.
    /// Tier 1 teaching boss - hazards vs deflection.
    ///
    /// Core mechanic: Alternates between deflectable and hazard attacks.
    /// Player must learn to read telegraphs - white flash = deflect, red glow = move.
    ///
    /// Proverb: "Light shows the path; fire decides where you may walk."
    /// </summary>
    public class ChochinObakeBoss : MonoBehaviour
    {
        [Header("Attacks")]
        [SerializeField] private AttackDefinition _tongueLashAttack;
        [SerializeField] private AttackDefinition _flameBreathAttack;

        [Header("Timing")]
        [SerializeField] private float _floatDuration = 1.2f;
        [SerializeField] private float _flickerDuration = 0.6f;
        [SerializeField] private float _staggerDuration = 1.5f;

        [Header("Behavior")]
        [Tooltip("If true, strictly alternates tongue/flame. If false, weighted random.")]
        [SerializeField] private bool _strictAlternation = true;
        [Tooltip("Chance to use FlameBreath when not alternating (0-1)")]
        [SerializeField] [Range(0f, 1f)] private float _flameChance = 0.4f;
        [SerializeField] private int _healthPoints = 2;

        private ChochinObakeState _state = ChochinObakeState.Inactive;
        private float _stateTimer;
        private int _currentHealth;
        private bool _lastAttackWasFlame;
        private int _attackCount;
        private AttackRunner _attackRunner;

        public ChochinObakeState State => _state;
        public int CurrentHealth => _currentHealth;
        public int AttackCount => _attackCount;

        public event Action<ChochinObakeState> OnStateChanged;
        public event Action<bool> OnAttackChosen; // true = flame (hazard), false = tongue (deflect)
        public event Action OnFlicker;
        public event Action OnDefeated;

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
            _attackCount = 0;
            _lastAttackWasFlame = true; // So first attack is TongueLash
            TransitionTo(ChochinObakeState.Intro);
        }

        private void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;

            switch (_state)
            {
                case ChochinObakeState.Intro:
                    if (_stateTimer >= 1.2f)
                    {
                        TransitionTo(ChochinObakeState.Float);
                    }
                    break;

                case ChochinObakeState.Float:
                    if (_stateTimer >= _floatDuration)
                    {
                        ChooseAndExecuteAttack();
                    }
                    break;

                case ChochinObakeState.Flicker:
                    if (_stateTimer >= _flickerDuration)
                    {
                        TransitionTo(ChochinObakeState.Float);
                    }
                    break;

                case ChochinObakeState.Staggered:
                    if (_stateTimer >= _staggerDuration)
                    {
                        TransitionTo(ChochinObakeState.Float);
                    }
                    break;
            }
        }

        private void ChooseAndExecuteAttack()
        {
            bool useFlame;

            if (_strictAlternation)
            {
                // Strict alternation: tongue → flame → tongue → flame
                useFlame = !_lastAttackWasFlame;
            }
            else
            {
                // Weighted random with bias against repeating
                float chance = _lastAttackWasFlame ? _flameChance * 0.5f : _flameChance;
                useFlame = UnityEngine.Random.value < chance;
            }

            _lastAttackWasFlame = useFlame;
            _attackCount++;

            OnAttackChosen?.Invoke(useFlame);

            if (useFlame)
                TransitionTo(ChochinObakeState.FlameBreath);
            else
                TransitionTo(ChochinObakeState.TongueLash);
        }

        private void TransitionTo(ChochinObakeState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;

            switch (newState)
            {
                case ChochinObakeState.TongueLash:
                    _attackRunner.Execute(_tongueLashAttack, transform);
                    break;

                case ChochinObakeState.FlameBreath:
                    _attackRunner.Execute(_flameBreathAttack, transform);
                    break;

                case ChochinObakeState.Flicker:
                    OnFlicker?.Invoke();
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == ChochinObakeState.TongueLash || _state == ChochinObakeState.FlameBreath)
            {
                TransitionTo(ChochinObakeState.Flicker);
            }
        }

        /// <summary>
        /// Called when the boss successfully hits the player with FlameBreath.
        /// </summary>
        public void NotifyFlameHitPlayer()
        {
            // Lantern burns brighter momentarily - visual feedback
        }

        public void ApplyStagger(float duration)
        {
            _staggerDuration = duration;
            _attackRunner.Cancel();
            TransitionTo(ChochinObakeState.Staggered);
        }

        public void TakeDamage()
        {
            _currentHealth--;
            if (_currentHealth <= 0)
            {
                Defeat();
            }
            else
            {
                TransitionTo(ChochinObakeState.Flicker);
            }
        }

        public void Defeat()
        {
            _attackRunner.Cancel();
            TransitionTo(ChochinObakeState.Defeated);
            OnDefeated?.Invoke();
        }

        /// <summary>
        /// Boss is vulnerable when staggered (after successful deflect of TongueLash).
        /// </summary>
        public bool IsVulnerable => _state == ChochinObakeState.Staggered;

        /// <summary>
        /// Returns true if the current/last attack was a hazard (FlameBreath).
        /// Used for death feedback - if player died to flame, they needed to reposition.
        /// </summary>
        public bool IsCurrentAttackHazard => _state == ChochinObakeState.FlameBreath;

        /// <summary>
        /// Returns the expected response for the current attack.
        /// </summary>
        public AttackResponse GetCurrentExpectedResponse()
        {
            return _state switch
            {
                ChochinObakeState.TongueLash => AttackResponse.Deflect,
                ChochinObakeState.FlameBreath => AttackResponse.Reposition,
                _ => AttackResponse.None
            };
        }
    }
}
