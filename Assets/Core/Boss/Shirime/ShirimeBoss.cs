using System;
using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Telegraphs;

namespace YokaiBlade.Core.Boss.Shirime
{
    public class ShirimeBoss : MonoBehaviour
    {
        [Header("Attacks")]
        [SerializeField] private AttackDefinition _eyeBeamAttack;
        [SerializeField] private AttackDefinition _punishAttack;

        [Header("Timing")]
        [SerializeField] private float _bowDuration = 2f;
        [SerializeField] private float _waitMinDuration = 1f;
        [SerializeField] private float _waitMaxDuration = 3f;
        [SerializeField] private float _staggerDuration = 1f;

        private ShirimeState _state = ShirimeState.Inactive;
        private float _stateTimer;
        private float _currentWaitDuration;
        private AttackRunner _attackRunner;
        private bool _playerAttackedDuringWait;

        public ShirimeState State => _state;
        public event Action<ShirimeState> OnStateChanged;
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
            TransitionTo(ShirimeState.Bow);
        }

        private void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;

            switch (_state)
            {
                case ShirimeState.Bow:
                    if (_stateTimer >= _bowDuration)
                        TransitionTo(ShirimeState.Wait);
                    break;

                case ShirimeState.Wait:
                    if (_stateTimer >= _currentWaitDuration)
                    {
                        if (_playerAttackedDuringWait)
                            TransitionTo(ShirimeState.Punish);
                        else
                            TransitionTo(ShirimeState.EyeBeam);
                    }
                    break;

                case ShirimeState.Staggered:
                    if (_stateTimer >= _staggerDuration)
                        TransitionTo(ShirimeState.Wait);
                    break;
            }
        }

        private void TransitionTo(ShirimeState newState)
        {
            if (_state == newState) return;

            _state = newState;
            _stateTimer = 0f;
            _playerAttackedDuringWait = false;

            switch (newState)
            {
                case ShirimeState.Wait:
                    _currentWaitDuration = UnityEngine.Random.Range(_waitMinDuration, _waitMaxDuration);
                    break;

                case ShirimeState.EyeBeam:
                    _attackRunner.Execute(_eyeBeamAttack, transform);
                    break;

                case ShirimeState.Punish:
                    _attackRunner.Execute(_punishAttack, transform);
                    break;
            }

            OnStateChanged?.Invoke(newState);
        }

        private void OnAttackEnded(AttackDefinition attack, bool completed)
        {
            if (_state == ShirimeState.EyeBeam || _state == ShirimeState.Punish)
            {
                TransitionTo(ShirimeState.Wait);
            }
        }

        public void NotifyPlayerAttacked()
        {
            if (_state == ShirimeState.Wait)
            {
                _playerAttackedDuringWait = true;
            }
        }

        public void ApplyStagger(float duration)
        {
            _staggerDuration = duration;
            TransitionTo(ShirimeState.Staggered);
        }

        public void Defeat()
        {
            _attackRunner?.Cancel();
            TransitionTo(ShirimeState.Defeated);
            OnDefeated?.Invoke();
        }

        public bool CanBeDefeated => _state == ShirimeState.Staggered;
    }
}
