using UnityEngine;

namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Configuration for input timing and buffering.
    /// All timing values are in seconds.
    /// </summary>
    [CreateAssetMenu(fileName = "InputConfig", menuName = "YokaiBlade/Input Config")]
    public class InputConfig : ScriptableObject
    {
        [Header("Buffer Windows")]
        [Tooltip("How long a deflect input stays in buffer (seconds).")]
        [Range(0.05f, 0.5f)]
        public float DeflectBufferWindow = 0.15f;

        [Tooltip("How long a strike input stays in buffer (seconds).")]
        [Range(0.05f, 0.5f)]
        public float StrikeBufferWindow = 0.1f;

        [Tooltip("How long a dodge input stays in buffer (seconds).")]
        [Range(0.05f, 0.5f)]
        public float DodgeBufferWindow = 0.1f;

        [Header("Deflect Timing")]
        [Tooltip("Perfect deflect window (seconds). Very tight.")]
        [Range(0.016f, 0.1f)]
        public float PerfectDeflectWindow = 0.05f;

        [Tooltip("Standard deflect window (seconds). More forgiving.")]
        [Range(0.05f, 0.2f)]
        public float StandardDeflectWindow = 0.15f;

        [Header("Action Lockout")]
        [Tooltip("Minimum time between combat actions (prevents spam).")]
        [Range(0f, 0.1f)]
        public float ActionCooldown = 0.05f;

        /// <summary>
        /// Get buffer window for a specific action.
        /// </summary>
        public float GetBufferWindow(InputAction action)
        {
            return action switch
            {
                InputAction.Deflect => DeflectBufferWindow,
                InputAction.Strike => StrikeBufferWindow,
                InputAction.Dodge => DodgeBufferWindow,
                _ => 0f
            };
        }

        /// <summary>
        /// Validate configuration values.
        /// </summary>
        public bool Validate(out string error)
        {
            if (PerfectDeflectWindow >= StandardDeflectWindow)
            {
                error = "Perfect deflect window must be smaller than standard window";
                return false;
            }

            if (DeflectBufferWindow <= 0 || StrikeBufferWindow <= 0 || DodgeBufferWindow <= 0)
            {
                error = "Buffer windows must be positive";
                return false;
            }

            error = null;
            return true;
        }

        private void OnValidate()
        {
            if (!Validate(out var error))
            {
                Debug.LogWarning($"[InputConfig] {error}");
            }
        }
    }
}
