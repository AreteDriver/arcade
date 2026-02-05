using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Core.Boss.Oni
{
    public class OniEncounter : MonoBehaviour
    {
        [SerializeField] private OniBoss _boss;
        [SerializeField] private PlayerController _player;
        [SerializeField] private DeflectSystem _deflectSystem;
        [SerializeField] private DeathFeedbackSystem _deathFeedback;
        [SerializeField] private HitDetector _bossHitDetector;
        [SerializeField] private HitDetector _playerHitDetector;

        private void OnEnable()
        {
            _player.OnActionExecuted += OnPlayerAction;
            _bossHitDetector.OnHit += OnBossAttackHit;
            _playerHitDetector.OnHit += OnPlayerAttackHit;
            _deflectSystem.OnDeflectAttempt += OnDeflectAttempt;
            _boss.OnDefeated += OnBossDefeated;
            _boss.OnPhaseChanged += OnPhaseChanged;
        }

        private void OnDisable()
        {
            _player.OnActionExecuted -= OnPlayerAction;
            _bossHitDetector.OnHit -= OnBossAttackHit;
            _playerHitDetector.OnHit -= OnPlayerAttackHit;
            _deflectSystem.OnDeflectAttempt -= OnDeflectAttempt;
            _boss.OnDefeated -= OnBossDefeated;
            _boss.OnPhaseChanged -= OnPhaseChanged;
        }

        public void Begin()
        {
            _boss.StartEncounter();
        }

        private void OnPlayerAction(InputAction action)
        {
            if (action == InputAction.Strike)
            {
                _boss.NotifyPlayerAttacked();
            }
            else if (action == InputAction.Deflect)
            {
                _deflectSystem.StartDeflect();
            }
        }

        private void OnBossAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Player")) return;

            var result = _deflectSystem.TryDeflect(attack, Time.fixedTime);

            if (result == DeflectResult.Miss)
            {
                _deathFeedback.TriggerDeath(attack, _player.transform.position);
                _player.Die();
            }
        }

        private void OnPlayerAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Boss")) return;

            if (_boss.IsVulnerable)
            {
                _boss.TakeDamage();
            }
        }

        private void OnDeflectAttempt(DeflectResult result, AttackDefinition attack)
        {
            if (result == DeflectResult.Perfect || result == DeflectResult.Standard)
            {
                float stagger = _deflectSystem.GetStaggerDuration(result);
                _boss.ApplyStagger(stagger);
            }
            _deflectSystem.EndDeflect();
        }

        private void OnPhaseChanged(OniPhase phase)
        {
            Debug.Log($"[OniEncounter] Phase {(int)phase}");
        }

        private void OnBossDefeated()
        {
            Debug.Log("[OniEncounter] VICTORY - Vertical Slice Complete!");
        }
    }
}
