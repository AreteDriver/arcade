using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss.Oni
{
    public class OniBoss : MonoBehaviour
    {
        [Header("Phase 1 - Heavy")]
        [SerializeField] private AttackDefinition _heavyStrike;

        [Header("Phase 2 - Counter")]
        [SerializeField] private AttackDefinition _counterStrike;
        [SerializeField] private float _counterStanceDuration = 2f;

        [Header("Phase 3 - Barehand")]
        [SerializeField] private AttackDefinition _comboHit1;
        [SerializeField] private AttackDefinition _comboHit2;
        [SerializeField] private AttackDefinition _comboHit3;

        [Header("Health")]
        [SerializeField] private int _phase1Health = 2;
        [SerializeField] private int _phase2Health = 2;
        [SerializeField] private int _phase3Health = 3;

        [Header("Timing")]
        [SerializeField] private float _idleDuration = 1f;

        private OniState _state = OniState.Inactive;
        private OniPhase _phase = OniPhase.Heavy;
        private float _stateTimer;
        private int _currentHealth;
        private int _comboIndex;
        private AttackRunner _attackRunner;
        private bool _playerAttackedDuringCounter;

        public OniState State => _state;
        public OniPhase Phase => _phase;
        public int CurrentHealth => _currentHealth;

        public event Action<OniState> OnStateChanged;
        public event Action<OniPhase> OnPhaseChanged;
        public event Action OnDefeated;

        private void Awake()
        {
            _attackRunner = GetComponent<AttackRunner>();
            if (_attackRunner == null)
                _attackRunner = gameObject.AddComponent<AttackRunner>();

            _attackRunner.OnAttackEnded += OnAttackEnded;
        }

        private void OnDestroy()
        {
            if (_attackRunner != null)
                _attackRunner.OnAttackEnded -= OnAttackEnded;
        }

        public void StartEncounter()
        {
            _phase = OniPhase.Heavy;
            _currentHealth = _phase1Health;
            TransitionTo(OniState.Intro);
        }

        private void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;

            switch (_state)
            {
                case OniState.Intro:
                    if (_stateTimer >= 1.5f)
                        TransitionTo(OniState.Idle);
                    break;

                case OniState.Idle:
                    if (_stateTimer >= _idleDuration)
                        ChooseNextAction();
                    break;

                case OniState.CounterStance:
                    if (_playerAttackedDuringCounter)
                    {
                        TransitionTo(OniState.CounterStrike);
                    }
                    else if (_stateTimer >= _counterStanceDuration)
                    {
                        TransitionTo(OniState.Idle);
                    }
                    break;

                case OniState.Staggered:
                    // External control
                    break;
            }
        }

        private void ChooseNextAction()
        {
            switch (_phase)
            {
                case OniPhase.Heavy:
                    TransitionTo(OniState.HeavyWindup);
                    break;

                case OniPhase.Counter:
                    if (UnityEngine.Random.value < 0.5f)
                        TransitionTo(OniState.CounterStance);
                    else
                        TransitionTo(OniState.HeavyWindup);
                    break;

                case OniPhase.Barehand:
                    _comboIndex = 0;
                    TransitionTo(OniState.ComboWindup);
                    break;
            }
        }

        private void TransitionTo(OniState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;
            _playerAttackedDuringCounter = false;

            switch (newState)
            {
                case OniState.HeavyWindup:
                case OniState.HeavyStrike:
                    _attackRunner.Execute(_heavyStrike, transform);
                    break;

                case OniState.CounterStrike:
                    _attackRunner.Execute(_counterStrike, transform);
                    break;

                case OniState.ComboWindup:
                case OniState.ComboChain:
                    ExecuteComboHit();
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void ExecuteComboHit()
        {
            var attack = _comboIndex switch
            {
                0 => _comboHit1,
                1 => _comboHit2,
                _ => _comboHit3
            };
            _attackRunner.Execute(attack, transform);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == OniState.ComboChain || _state == OniState.ComboWindup)
            {
                _comboIndex++;
                if (_comboIndex < 3)
                {
                    TransitionTo(OniState.ComboChain);
                }
                else
                {
                    TransitionTo(OniState.Idle);
                }
            }
            else
            {
                TransitionTo(OniState.Idle);
            }
        }

        public void NotifyPlayerAttacked()
        {
            if (_state == OniState.CounterStance)
            {
                _playerAttackedDuringCounter = true;
            }
        }

        public void ApplyStagger(float duration)
        {
            TransitionTo(OniState.Staggered);
        }

        public void TakeDamage()
        {
            _currentHealth--;

            if (_currentHealth <= 0)
            {
                if (_phase == OniPhase.Barehand)
                {
                    Defeat();
                }
                else
                {
                    AdvancePhase();
                }
            }
            else
            {
                TransitionTo(OniState.Idle);
            }
        }

        private void AdvancePhase()
        {
            _phase = _phase switch
            {
                OniPhase.Heavy => OniPhase.Counter,
                OniPhase.Counter => OniPhase.Barehand,
                _ => OniPhase.Barehand
            };

            _currentHealth = _phase switch
            {
                OniPhase.Counter => _phase2Health,
                OniPhase.Barehand => _phase3Health,
                _ => 1
            };

            OnPhaseChanged?.Invoke(_phase);
            TransitionTo(OniState.Idle);
        }

        public void Defeat()
        {
            _attackRunner?.Cancel();
            TransitionTo(OniState.Defeated);
            OnDefeated?.Invoke();
        }

        public bool IsVulnerable => _state == OniState.Staggered;
    }
}
