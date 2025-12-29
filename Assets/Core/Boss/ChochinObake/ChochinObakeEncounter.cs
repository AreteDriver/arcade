using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Core.Boss.ChochinObake
{
    /// <summary>
    /// Encounter controller for Chochin-Obake.
    /// Wires boss, player, deflect system, and hit detection together.
    ///
    /// Key teaching: TongueLash = deflect, FlameBreath = reposition.
    /// Trying to deflect fire = death. Standing still during fire = death.
    /// </summary>
    public class ChochinObakeEncounter : MonoBehaviour
    {
        [SerializeField] private ChochinObakeBoss _boss;
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
            _boss.OnAttackChosen += OnBossAttackChosen;

            if (_playerHitDetector != null)
                _playerHitDetector.OnHit += OnPlayerAttackHit;
        }

        private void OnDisable()
        {
            _player.OnActionExecuted -= OnPlayerAction;
            _bossHitDetector.OnHit -= OnBossAttackHit;
            _deflectSystem.OnDeflectAttempt -= OnDeflectAttempt;
            _boss.OnDefeated -= OnBossDefeated;
            _boss.OnAttackChosen -= OnBossAttackChosen;

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

        private void OnBossAttackChosen(bool isFlame)
        {
            // Audio/visual feedback for attack type
            // TongueLash: physical whoosh sound
            // FlameBreath: fire crackling + red glow warning
            Debug.Log($"[ChochinObakeEncounter] Attack chosen: {(isFlame ? "FLAME (reposition!)" : "TONGUE (deflect!)")}");
        }

        private void OnBossAttackHit(AttackDefinition attack, Collider target)
        {
            if (!target.CompareTag("Player")) return;

            // Check if this is a hazard attack
            bool isHazard = _boss.IsCurrentAttackHazard;

            if (isHazard)
            {
                // FlameBreath - cannot be deflected
                // Player should have repositioned
                _boss.NotifyFlameHitPlayer();
                _deathFeedback.TriggerDeath(attack, _player.transform.position);
                _player.Die();
            }
            else
            {
                // TongueLash - can be deflected
                var result = _deflectSystem.TryDeflect(attack, Time.fixedTime);

                if (result == DeflectResult.Miss)
                {
                    _deathFeedback.TriggerDeath(attack, _player.transform.position);
                    _player.Die();
                }
            }
        }

        private void OnDeflectAttempt(DeflectResult result, AttackDefinition attack)
        {
            // Only TongueLash can be deflected - FlameBreath bypasses deflect entirely
            if (_boss.IsCurrentAttackHazard)
            {
                // Player tried to deflect fire - this doesn't help
                // The hit will still land and kill them
                Debug.Log("[ChochinObakeEncounter] Cannot deflect fire! Must reposition!");
                return;
            }

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

            if (_boss.IsVulnerable)
            {
                _boss.TakeDamage();
            }
        }

        private void OnBossDefeated()
        {
            Debug.Log("[ChochinObakeEncounter] Victory! You have learned to read the light.");
        }
    }
}
