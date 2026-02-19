using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Core.Boss.Shirime
{
    public class ShirimeEncounter : MonoBehaviour
    {
        [SerializeField] private ShirimeBoss _boss;
        [SerializeField] private PlayerController _player;
        [SerializeField] private DeflectSystem _deflectSystem;
        [SerializeField] private DeathFeedbackSystem _deathFeedback;
        [SerializeField] private HitDetector _bossHitDetector;

        private AttackRunner _bossAttackRunner;

        private void Awake()
        {
            _bossAttackRunner = _boss.GetComponent<AttackRunner>();
        }

        private void OnEnable()
        {
            _player.OnActionExecuted += OnPlayerAction;
            _bossHitDetector.OnHit += OnBossAttackHit;
            _deflectSystem.OnDeflectAttempt += OnDeflectAttempt;
            _boss.OnDefeated += OnBossDefeated;
        }

        private void OnDisable()
        {
            _player.OnActionExecuted -= OnPlayerAction;
            _bossHitDetector.OnHit -= OnBossAttackHit;
            _deflectSystem.OnDeflectAttempt -= OnDeflectAttempt;
            _boss.OnDefeated -= OnBossDefeated;
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

        private void OnDeflectAttempt(DeflectResult result, AttackDefinition attack)
        {
            if (result == DeflectResult.Perfect)
            {
                float stagger = _deflectSystem.GetStaggerDuration(result);
                _boss.ApplyStagger(stagger);

                if (_boss.CanBeDefeated)
                {
                    _boss.Defeat();
                }
            }
            else if (result == DeflectResult.Standard)
            {
                float stagger = _deflectSystem.GetStaggerDuration(result);
                _boss.ApplyStagger(stagger);
            }

            _deflectSystem.EndDeflect();
        }

        private void OnBossDefeated()
        {
            Debug.Log("[ShirimeEncounter] Victory!");
        }
    }
}
