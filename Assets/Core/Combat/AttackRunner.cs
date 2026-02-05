using System;
using UnityEngine;
using YokaiBlade.Core.Telegraphs;

namespace YokaiBlade.Core.Combat
{
    public class AttackRunner : MonoBehaviour
    {
        public event Action<AttackDefinition> OnAttackStarted;
        public event Action<AttackDefinition, AttackPhase> OnPhaseChanged;
        public event Action<AttackDefinition, bool> OnAttackEnded; // bool = completed (not interrupted)
        public event Action<AttackDefinition> OnHitFrameActive;

        private AttackDefinition _current;
        private AttackPhase _phase;
        private float _phaseTimer;
        private float _totalTimer;
        private bool _telegraphEmitted;
        private bool _hitActive;
        private Transform _source;

        public bool IsRunning => _current != null;
        public AttackDefinition Current => _current;
        public AttackPhase Phase => _phase;

        public void Execute(AttackDefinition attack, Transform source)
        {
            if (attack == null) return;

            _current = attack;
            _source = source;
            _phase = AttackPhase.Startup;
            _phaseTimer = 0f;
            _totalTimer = 0f;
            _telegraphEmitted = false;
            _hitActive = false;

            OnAttackStarted?.Invoke(attack);
            OnPhaseChanged?.Invoke(attack, AttackPhase.Startup);
        }

        public void Cancel()
        {
            if (_current == null) return;
            var attack = _current;
            _current = null;
            _phase = AttackPhase.None;
            _hitActive = false;
            OnAttackEnded?.Invoke(attack, false);
        }

        private void FixedUpdate()
        {
            if (_current == null) return;

            float dt = Time.fixedDeltaTime;
            _phaseTimer += dt;
            _totalTimer += dt;

            // Telegraph emission
            if (!_telegraphEmitted && _totalTimer >= _current.TelegraphTime)
            {
                _telegraphEmitted = true;
                TelegraphSystem.Emit(_current.Telegraph, _source, _current.AttackId);
            }

            // Phase transitions
            switch (_phase)
            {
                case AttackPhase.Startup:
                    if (_phaseTimer >= _current.StartupDuration)
                    {
                        TransitionTo(AttackPhase.Active);
                    }
                    break;

                case AttackPhase.Active:
                    if (!_hitActive)
                    {
                        _hitActive = true;
                        OnHitFrameActive?.Invoke(_current);
                    }
                    if (_phaseTimer >= _current.ActiveDuration)
                    {
                        _hitActive = false;
                        TransitionTo(AttackPhase.Recovery);
                    }
                    break;

                case AttackPhase.Recovery:
                    if (_phaseTimer >= _current.RecoveryDuration)
                    {
                        Complete();
                    }
                    break;
            }
        }

        private void TransitionTo(AttackPhase newPhase)
        {
            _phase = newPhase;
            _phaseTimer = 0f;
            OnPhaseChanged?.Invoke(_current, newPhase);
        }

        private void Complete()
        {
            var attack = _current;
            _current = null;
            _phase = AttackPhase.None;
            OnAttackEnded?.Invoke(attack, true);
        }

        public AttackPhase GetPhaseAtTime(AttackDefinition attack, float time)
        {
            if (time < 0) return AttackPhase.None;
            if (time < attack.StartupDuration) return AttackPhase.Startup;
            if (time < attack.StartupDuration + attack.ActiveDuration) return AttackPhase.Active;
            if (time < attack.TotalDuration) return AttackPhase.Recovery;
            return AttackPhase.None;
        }
    }
}
