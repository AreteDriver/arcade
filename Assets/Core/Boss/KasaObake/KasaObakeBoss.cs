using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss.KasaObake
{
    /// <summary>
    /// Kasa-Obake: The umbrella yokai.
    /// Tier 1 teaching boss - timing through playfulness.
    ///
    /// Core mechanic: Rhythmic hopping pattern (1-2-3).
    /// On the 3rd hop, always attacks. Player learns to count and predict.
    ///
    /// Proverb: "Even the foolish reveal their rhythm if you watch them long enough."
    /// </summary>
    public class KasaObakeBoss : MonoBehaviour
    {
        [Header("Attacks")]
        [SerializeField] private AttackDefinition _tongueLashAttack;
        [SerializeField] private AttackDefinition _spinAttack;

        [Header("Rhythm Timing")]
        [Tooltip("Duration of each hop in the 1-2-3 pattern")]
        [SerializeField] private float _hopDuration = 0.5f;
        [Tooltip("Brief pause after completing a hop cycle")]
        [SerializeField] private float _cycleRestDuration = 0.3f;

        [Header("Behavior")]
        [Tooltip("Chance to use Spin instead of TongueLash (0-1)")]
        [SerializeField] [Range(0f, 1f)] private float _spinChance = 0.25f;
        [SerializeField] private float _tauntDuration = 0.8f;
        [SerializeField] private float _staggerDuration = 1.2f;
        [SerializeField] private int _healthPoints = 2;

        private KasaObakeState _state = KasaObakeState.Inactive;
        private float _stateTimer;
        private int _hopCount;
        private int _currentHealth;
        private bool _nextAttackIsSpin;
        private AttackRunner _attackRunner;

        public KasaObakeState State => _state;
        public int CurrentHealth => _currentHealth;
        public int HopCount => _hopCount;

        public event Action<KasaObakeState> OnStateChanged;
        public event Action<int> OnHop; // hop number 1, 2, or 3
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
            _hopCount = 0;
            TransitionTo(KasaObakeState.Intro);
        }

        private void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;

            switch (_state)
            {
                case KasaObakeState.Intro:
                    if (_stateTimer >= 1f)
                    {
                        _hopCount = 0;
                        TransitionTo(KasaObakeState.Hopping);
                    }
                    break;

                case KasaObakeState.Hopping:
                    UpdateHopping();
                    break;

                case KasaObakeState.Taunt:
                    if (_stateTimer >= _tauntDuration)
                    {
                        _hopCount = 0;
                        TransitionTo(KasaObakeState.Hopping);
                    }
                    break;

                case KasaObakeState.Staggered:
                    if (_stateTimer >= _staggerDuration)
                    {
                        _hopCount = 0;
                        TransitionTo(KasaObakeState.Hopping);
                    }
                    break;
            }
        }

        private void UpdateHopping()
        {
            if (_stateTimer >= _hopDuration)
            {
                _hopCount++;
                _stateTimer = 0f;

                if (_hopCount <= 3)
                {
                    OnHop?.Invoke(_hopCount);
                }

                // On hop 2, decide what attack is coming
                if (_hopCount == 2)
                {
                    _nextAttackIsSpin = UnityEngine.Random.value < _spinChance;
                    // Visual telegraph: wobble animation would play here for spin
                }

                // On hop 3, execute attack
                if (_hopCount >= 3)
                {
                    if (_nextAttackIsSpin)
                        TransitionTo(KasaObakeState.Spin);
                    else
                        TransitionTo(KasaObakeState.TongueLash);
                }
            }
        }

        private void TransitionTo(KasaObakeState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;

            switch (newState)
            {
                case KasaObakeState.TongueLash:
                    _attackRunner.Execute(_tongueLashAttack, transform);
                    break;

                case KasaObakeState.Spin:
                    _attackRunner.Execute(_spinAttack, transform);
                    break;

                case KasaObakeState.Hopping:
                    _hopCount = 0;
                    _nextAttackIsSpin = false;
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == KasaObakeState.TongueLash || _state == KasaObakeState.Spin)
            {
                // After attack, brief rest then resume hopping
                _hopCount = 0;
                TransitionTo(KasaObakeState.Hopping);
            }
        }

        /// <summary>
        /// Called when the boss successfully hits the player.
        /// Triggers a brief taunt animation.
        /// </summary>
        public void NotifyHitPlayer()
        {
            if (_state == KasaObakeState.TongueLash || _state == KasaObakeState.Spin)
            {
                _attackRunner?.Cancel();
                TransitionTo(KasaObakeState.Taunt);
            }
        }

        public void ApplyStagger(float duration)
        {
            _staggerDuration = duration;
            _attackRunner?.Cancel();
            TransitionTo(KasaObakeState.Staggered);
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
                _hopCount = 0;
                TransitionTo(KasaObakeState.Hopping);
            }
        }

        public void Defeat()
        {
            _attackRunner?.Cancel();
            TransitionTo(KasaObakeState.Defeated);
            OnDefeated?.Invoke();
        }

        /// <summary>
        /// Boss is vulnerable when staggered (after successful deflect).
        /// </summary>
        public bool IsVulnerable => _state == KasaObakeState.Staggered;

        /// <summary>
        /// Returns true if boss is about to use Spin attack.
        /// UI/animation can use this to show wobble telegraph on hop 2.
        /// </summary>
        public bool IsSpinTelegraphed => _hopCount == 2 && _nextAttackIsSpin;

        /// <summary>
        /// Manually triggers a hop. Used for testing and scripted sequences.
        /// In normal gameplay, hops occur via FixedUpdate timing.
        /// </summary>
        public void TriggerHop()
        {
            if (_state != KasaObakeState.Hopping && _state != KasaObakeState.Intro)
                return;

            _hopCount++;
            OnHop?.Invoke(_hopCount);

            if (_hopCount == 2)
            {
                _nextAttackIsSpin = UnityEngine.Random.value < _spinChance;
            }

            if (_hopCount >= 3)
            {
                if (_nextAttackIsSpin)
                    TransitionTo(KasaObakeState.Spin);
                else
                    TransitionTo(KasaObakeState.TongueLash);
            }
        }
    }
}
