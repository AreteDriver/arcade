using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss.Tanuki
{
    public class TanukiBoss : MonoBehaviour
    {
        [Header("Attacks")]
        [SerializeField] private AttackDefinition _realAttack;
        [SerializeField] private AttackDefinition _counterAttack;

        [Header("Timing")]
        [SerializeField] private float _idleDuration = 1.5f;
        [SerializeField] private float _transformDuration = 0.5f;
        [SerializeField] private float _disguisedMinDuration = 2f;
        [SerializeField] private float _disguisedMaxDuration = 4f;
        [SerializeField] private float _fakeAttackDuration = 0.8f;

        [Header("Behavior")]
        [SerializeField] [Range(0f, 1f)] private float _fakeAttackChance = 0.4f;
        [SerializeField] private int _healthPoints = 3;

        private TanukiState _state = TanukiState.Inactive;
        private float _stateTimer;
        private float _currentDisguiseDuration;
        private int _currentHealth;
        private AttackRunner _attackRunner;
        private bool _playerAttackedDuringDisguise;

        public TanukiState State => _state;
        public int CurrentHealth => _currentHealth;
        public event Action<TanukiState> OnStateChanged;
        public event Action OnDefeated;
        public event Action<int> OnTransform; // disguise index

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
            TransitionTo(TanukiState.Intro);
        }

        private void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;

            switch (_state)
            {
                case TanukiState.Intro:
                    if (_stateTimer >= 1f)
                        TransitionTo(TanukiState.Idle);
                    break;

                case TanukiState.Idle:
                    if (_stateTimer >= _idleDuration)
                        TransitionTo(TanukiState.Transforming);
                    break;

                case TanukiState.Transforming:
                    if (_stateTimer >= _transformDuration)
                        TransitionTo(TanukiState.Disguised);
                    break;

                case TanukiState.Disguised:
                    if (_playerAttackedDuringDisguise)
                    {
                        TransitionTo(TanukiState.Counter);
                    }
                    else if (_stateTimer >= _currentDisguiseDuration)
                    {
                        if (UnityEngine.Random.value < _fakeAttackChance)
                            TransitionTo(TanukiState.FakeAttack);
                        else
                            TransitionTo(TanukiState.RealAttack);
                    }
                    break;

                case TanukiState.FakeAttack:
                    if (_stateTimer >= _fakeAttackDuration)
                        TransitionTo(TanukiState.RealAttack);
                    break;

                case TanukiState.Staggered:
                    // Wait for external transition
                    break;
            }
        }

        private void TransitionTo(TanukiState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;
            _playerAttackedDuringDisguise = false;

            switch (newState)
            {
                case TanukiState.Transforming:
                    OnTransform?.Invoke(UnityEngine.Random.Range(0, 5));
                    break;

                case TanukiState.Disguised:
                    _currentDisguiseDuration = UnityEngine.Random.Range(_disguisedMinDuration, _disguisedMaxDuration);
                    break;

                case TanukiState.RealAttack:
                    _attackRunner.Execute(_realAttack, transform);
                    break;

                case TanukiState.Counter:
                    _attackRunner.Execute(_counterAttack, transform);
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == TanukiState.RealAttack || _state == TanukiState.Counter)
            {
                TransitionTo(TanukiState.Idle);
            }
        }

        public void NotifyPlayerAttacked()
        {
            if (_state == TanukiState.Disguised)
            {
                _playerAttackedDuringDisguise = true;
            }
        }

        public void ApplyStagger(float duration)
        {
            TransitionTo(TanukiState.Staggered);
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
                TransitionTo(TanukiState.Idle);
            }
        }

        public void Defeat()
        {
            _attackRunner?.Cancel();
            TransitionTo(TanukiState.Defeated);
            OnDefeated?.Invoke();
        }

        public bool IsVulnerable => _state == TanukiState.Staggered;
    }
}
