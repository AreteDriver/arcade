using System;
using UnityEngine;

namespace YokaiBlade.Core.Combat
{
    [Serializable]
    public struct DeathFeedbackData
    {
        public string AttackName;
        public AttackResponse CorrectResponse;
        public Vector3 DeathPosition;
        public float TimeOfDeath;
    }

    public class DeathFeedbackSystem : MonoBehaviour
    {
        [Header("Timing")]
        [SerializeField] private float _freezeDuration = 1f;
        [SerializeField] private float _panelDisplayDuration = 2f;

        public event Action<DeathFeedbackData> OnDeathTriggered;
        public event Action OnFreezeEnd;
        public event Action OnReadyToRetry;

        private DeathFeedbackData _lastDeath;
        private bool _isFrozen;
        private float _freezeTimer;
        private float _originalTimeScale;

        public bool IsFrozen => _isFrozen;
        public DeathFeedbackData LastDeath => _lastDeath;

        public void TriggerDeath(AttackDefinition attack, Vector3 position)
        {
            _lastDeath = new DeathFeedbackData
            {
                AttackName = attack.DisplayName ?? attack.AttackId,
                CorrectResponse = attack.CorrectResponse,
                DeathPosition = position,
                TimeOfDeath = Time.unscaledTime
            };

            StartFreeze();
            OnDeathTriggered?.Invoke(_lastDeath);
        }

        private void StartFreeze()
        {
            _isFrozen = true;
            _freezeTimer = 0f;
            _originalTimeScale = Time.timeScale;
            Time.timeScale = 0f;
        }

        private void Update()
        {
            if (!_isFrozen) return;

            _freezeTimer += Time.unscaledDeltaTime;

            if (_freezeTimer >= _freezeDuration)
            {
                EndFreeze();
            }
        }

        private void EndFreeze()
        {
            _isFrozen = false;
            Time.timeScale = _originalTimeScale;
            OnFreezeEnd?.Invoke();

            // After freeze, show panel briefly then allow retry
            Invoke(nameof(SignalReadyToRetry), _panelDisplayDuration);
        }

        private void SignalReadyToRetry()
        {
            OnReadyToRetry?.Invoke();
        }

        public void ForceRetry()
        {
            CancelInvoke(nameof(SignalReadyToRetry));
            if (_isFrozen)
            {
                Time.timeScale = _originalTimeScale;
                _isFrozen = false;
            }
            OnReadyToRetry?.Invoke();
        }

        private void OnDestroy()
        {
            if (_isFrozen)
            {
                Time.timeScale = _originalTimeScale;
            }
        }
    }
}
