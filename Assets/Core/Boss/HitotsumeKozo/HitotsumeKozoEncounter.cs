using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Core.Boss.HitotsumeKozo
{
    /// <summary>
    /// Encounter controller for Hitotsume-Kozo.
    /// Wires boss, player, deflect system, and hit detection together.
    ///
    /// Key teaching: Passive play = boss regenerates.
    /// Must chase and attack during taunt windows.
    /// Cornered boss does panic attack that must be deflected.
    /// </summary>
    public class HitotsumeKozoEncounter : MonoBehaviour
    {
        [SerializeField] private HitotsumeKozoBoss _boss;
        [SerializeField] private PlayerController _player;
        [SerializeField] private DeflectSystem _deflectSystem;
        [SerializeField] private DeathFeedbackSystem _deathFeedback;
        [SerializeField] private HitDetector _bossHitDetector;
        [SerializeField] private HitDetector _playerHitDetector;

        [Header("Chase Detection")]
        [SerializeField] private float _catchDistance = 2f;

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
            _boss.OnRegenerate += OnBossRegenerate;
            _boss.OnPressureWarning += OnPressureWarning;
            _boss.OnTaunt += OnBossTaunt;

            if (_playerHitDetector != null)
                _playerHitDetector.OnHit += OnPlayerAttackHit;
        }

        private void OnDisable()
        {
            _player.OnActionExecuted -= OnPlayerAction;
            _bossHitDetector.OnHit -= OnBossAttackHit;
            _deflectSystem.OnDeflectAttempt -= OnDeflectAttempt;
            _boss.OnDefeated -= OnBossDefeated;
            _boss.OnRegenerate -= OnBossRegenerate;
            _boss.OnPressureWarning -= OnPressureWarning;
            _boss.OnTaunt -= OnBossTaunt;

            if (_playerHitDetector != null)
                _playerHitDetector.OnHit -= OnPlayerAttackHit;
        }

        private void FixedUpdate()
        {
            // Check if player has caught up to boss during flee/taunt
            if (_boss.State == HitotsumeKozoState.Flee ||
                _boss.State == HitotsumeKozoState.Taunt)
            {
                float distance = Vector3.Distance(_player.transform.position, _boss.transform.position);
                if (distance <= _catchDistance)
                {
                    _boss.NotifyPlayerCaughtUp();
                }
            }
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

        private void OnBossTaunt()
        {
            Debug.Log("[HitotsumeKozoEncounter] Boss is taunting! Attack now!");
        }

        private void OnPressureWarning()
        {
            Debug.Log("[HitotsumeKozoEncounter] WARNING: Boss will regenerate soon! Apply pressure!");
        }

        private void OnBossRegenerate(int amount)
        {
            Debug.Log($"[HitotsumeKozoEncounter] Boss regenerated {amount} HP! Don't let it rest!");
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
            if (result == DeflectResult.Perfect || result == DeflectResult.Standard)
            {
                float stagger = _deflectSystem.GetStaggerDuration(result);
                _boss.ApplyStagger(stagger);
            }

            _deflectSystem.EndDeflect();
        }

        private void OnPlayerAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Boss")) return;

            // Can damage boss during taunt OR when staggered
            if (_boss.IsOpenToAttack)
            {
                _boss.TakeDamage();
            }
            else
            {
                // Attack landed but boss isn't vulnerable - just reset pressure
                _boss.NotifyPlayerAttacked();
            }
        }

        private void OnBossDefeated()
        {
            Debug.Log("[HitotsumeKozoEncounter] Victory! The coward could not escape your blade.");
        }
    }
}
