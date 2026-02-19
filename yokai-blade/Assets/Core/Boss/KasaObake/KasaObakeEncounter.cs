using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Core.Boss.KasaObake
{
    /// <summary>
    /// Encounter controller for Kasa-Obake.
    /// Wires boss, player, deflect system, and hit detection together.
    ///
    /// Victory condition: Stagger boss with deflects, then deal damage.
    /// Boss has 2 HP - requires two successful damage phases.
    /// </summary>
    public class KasaObakeEncounter : MonoBehaviour
    {
        [SerializeField] private KasaObakeBoss _boss;
        [SerializeField] private PlayerController _player;
        [SerializeField] private DeflectSystem _deflectSystem;
        [SerializeField] private DeathFeedbackSystem _deathFeedback;
        [SerializeField] private HitDetector _bossHitDetector;
        [SerializeField] private HitDetector _playerHitDetector;

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
            _boss.OnHop += OnBossHop;

            if (_playerHitDetector != null)
                _playerHitDetector.OnHit += OnPlayerAttackHit;
        }

        private void OnDisable()
        {
            _player.OnActionExecuted -= OnPlayerAction;
            _bossHitDetector.OnHit -= OnBossAttackHit;
            _deflectSystem.OnDeflectAttempt -= OnDeflectAttempt;
            _boss.OnDefeated -= OnBossDefeated;
            _boss.OnHop -= OnBossHop;

            if (_playerHitDetector != null)
                _playerHitDetector.OnHit -= OnPlayerAttackHit;
        }

        public void Begin()
        {
            _boss.StartEncounter();
        }

        private void OnPlayerAction(InputAction action)
        {
            if (action == InputAction.Deflect)
            {
                _deflectSystem.StartDeflect();
            }
        }

        private void OnBossHop(int hopNumber)
        {
            // Audio/visual feedback for rhythm
            // Hop 1: light sound
            // Hop 2: medium sound (+ wobble if spin incoming)
            // Hop 3: attack incoming
            Debug.Log($"[KasaObakeEncounter] Hop {hopNumber}" +
                (hopNumber == 2 && _boss.IsSpinTelegraphed ? " (SPIN INCOMING!)" : ""));
        }

        private void OnBossAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Player")) return;

            var result = _deflectSystem.TryDeflect(attack, Time.fixedTime);

            if (result == DeflectResult.Miss)
            {
                _boss.NotifyHitPlayer();
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
            }
            else if (result == DeflectResult.Standard)
            {
                float stagger = _deflectSystem.GetStaggerDuration(result);
                _boss.ApplyStagger(stagger);
            }

            _deflectSystem.EndDeflect();
        }

        private void OnPlayerAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Boss")) return;

            if (_boss.IsVulnerable)
            {
                _boss.TakeDamage();
            }
        }

        private void OnBossDefeated()
        {
            Debug.Log("[KasaObakeEncounter] Victory! The rhythm has been mastered.");
        }
    }
}
