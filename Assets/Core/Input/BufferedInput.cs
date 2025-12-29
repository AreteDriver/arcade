namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Represents a buffered input waiting to be consumed.
    /// Stores the action and timing information for consistent replay.
    /// </summary>
    public readonly struct BufferedInput
    {
        /// <summary>
        /// The action that was buffered.
        /// </summary>
        public readonly InputAction Action;

        /// <summary>
        /// Fixed time when the input was registered.
        /// Uses FixedTime for frame-rate independent replay.
        /// </summary>
        public readonly float Timestamp;

        /// <summary>
        /// How long this input remains valid in the buffer (seconds).
        /// </summary>
        public readonly float BufferWindow;

        public BufferedInput(InputAction action, float timestamp, float bufferWindow)
        {
            Action = action;
            Timestamp = timestamp;
            BufferWindow = bufferWindow;
        }

        /// <summary>
        /// Check if this buffered input is still valid.
        /// </summary>
        public bool IsValid(float currentTime)
        {
            return currentTime - Timestamp <= BufferWindow;
        }

        /// <summary>
        /// Check if this input has expired.
        /// </summary>
        public bool IsExpired(float currentTime)
        {
            return !IsValid(currentTime);
        }

        /// <summary>
        /// Time remaining before this input expires.
        /// </summary>
        public float TimeRemaining(float currentTime)
        {
            float remaining = BufferWindow - (currentTime - Timestamp);
            return remaining > 0 ? remaining : 0f;
        }

        public override string ToString()
        {
            return $"[{Action} @ {Timestamp:F3}]";
        }
    }
}
