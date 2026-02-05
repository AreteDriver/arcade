using System;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.Boss
{
    public abstract class BossBase : MonoBehaviour
    {
        [Header("Base")]
        [SerializeField] protected AttackRunner _attackRunner;

        protected BossState _state = BossState.Inactive;
        protected float _stateTimer;

        public BossState State => _state;
        public event Action<BossState, BossState> OnStateChanged;
        public event Action OnDefeated;

        protected virtual void Awake()
        {
            if (_attackRunner == null)
                _attackRunner = GetComponent<AttackRunner>();
        }

        protected virtual void FixedUpdate()
        {
            _stateTimer += Time.fixedDeltaTime;
            UpdateState();
        }

        protected abstract void UpdateState();

        protected void TransitionTo(BossState newState)
        {
            if (_state == newState) return;
            var old = _state;
            _state = newState;
            _stateTimer = 0f;
            OnStateChanged?.Invoke(old, newState);
            OnEnterState(newState);
        }

        protected virtual void OnEnterState(BossState state) { }

        public virtual void StartEncounter()
        {
            TransitionTo(BossState.Intro);
        }

        public virtual void ApplyStagger(float duration)
        {
            TransitionTo(BossState.Staggered);
        }

        protected void Defeat()
        {
            TransitionTo(BossState.Defeated);
            OnDefeated?.Invoke();
        }
    }
}
