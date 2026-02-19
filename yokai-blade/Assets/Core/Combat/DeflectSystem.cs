using System;
using UnityEngine;

namespace YokaiBlade.Core.Combat
{
    public class DeflectSystem : MonoBehaviour
    {
        [Header("Windows (seconds)")]
        [SerializeField] private float _perfectWindow = 0.05f;
        [SerializeField] private float _standardWindow = 0.15f;

        [Header("Rewards")]
        [SerializeField] private int _perfectMeterGain = 20;
        [SerializeField] private int _standardMeterGain = 5;
        [SerializeField] private float _perfectStaggerDuration = 1f;
        [SerializeField] private float _standardStaggerDuration = 0.3f;

        public event Action<DeflectResult, AttackDefinition> OnDeflectAttempt;

        private float _deflectStartTime;
        private bool _deflectActive;

        public bool IsDeflecting => _deflectActive;
        public float PerfectWindow => _perfectWindow;
        public float StandardWindow => _standardWindow;

        public void StartDeflect()
        {
            _deflectActive = true;
            _deflectStartTime = Time.fixedTime;
        }

        public void EndDeflect()
        {
            _deflectActive = false;
        }

        public DeflectResult TryDeflect(AttackDefinition attack, float hitTime)
        {
            if (!_deflectActive) return DeflectResult.Miss;
            if (attack.Unblockable) return DeflectResult.Miss;

            float elapsed = hitTime - _deflectStartTime;

            DeflectResult result;
            if (elapsed <= _perfectWindow)
            {
                result = DeflectResult.Perfect;
            }
            else if (elapsed <= _standardWindow)
            {
                result = DeflectResult.Standard;
            }
            else
            {
                result = DeflectResult.Miss;
            }

            OnDeflectAttempt?.Invoke(result, attack);
            return result;
        }

        public int GetMeterGain(DeflectResult result)
        {
            return result switch
            {
                DeflectResult.Perfect => _perfectMeterGain,
                DeflectResult.Standard => _standardMeterGain,
                _ => 0
            };
        }

        public float GetStaggerDuration(DeflectResult result)
        {
            return result switch
            {
                DeflectResult.Perfect => _perfectStaggerDuration,
                DeflectResult.Standard => _standardStaggerDuration,
                _ => 0f
            };
        }

        public DeflectResult EvaluateWindow(float elapsed)
        {
            if (elapsed <= _perfectWindow) return DeflectResult.Perfect;
            if (elapsed <= _standardWindow) return DeflectResult.Standard;
            return DeflectResult.Miss;
        }
    }
}
