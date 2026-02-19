using UnityEngine;

namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Context data passed with telegraph emissions.
    /// Provides spatial and timing information without altering semantic meaning.
    /// </summary>
    public readonly struct TelegraphContext
    {
        /// <summary>
        /// World position where the telegraph originates.
        /// </summary>
        public readonly Vector3 Position;

        /// <summary>
        /// Optional direction the telegraph faces or travels.
        /// </summary>
        public readonly Vector3 Direction;

        /// <summary>
        /// Duration in seconds the telegraph should display.
        /// Zero means use catalog default.
        /// </summary>
        public readonly float Duration;

        /// <summary>
        /// Source transform (e.g., the boss emitting the telegraph).
        /// May be null for world-space telegraphs.
        /// </summary>
        public readonly Transform Source;

        /// <summary>
        /// Optional identifier for the specific attack triggering this telegraph.
        /// Used for logging and debugging, never for semantic interpretation.
        /// </summary>
        public readonly string AttackId;

        public TelegraphContext(
            Vector3 position,
            Vector3 direction = default,
            float duration = 0f,
            Transform source = null,
            string attackId = null)
        {
            Position = position;
            Direction = direction == default ? Vector3.forward : direction;
            Duration = duration;
            Source = source;
            AttackId = attackId ?? string.Empty;
        }

        /// <summary>
        /// Create context from a transform's current state.
        /// </summary>
        public static TelegraphContext FromTransform(Transform t, string attackId = null, float duration = 0f)
        {
            return new TelegraphContext(
                position: t.position,
                direction: t.forward,
                duration: duration,
                source: t,
                attackId: attackId
            );
        }

        /// <summary>
        /// Create context for a world-space position with no source.
        /// </summary>
        public static TelegraphContext AtPosition(Vector3 position, string attackId = null, float duration = 0f)
        {
            return new TelegraphContext(
                position: position,
                duration: duration,
                attackId: attackId
            );
        }
    }
}
