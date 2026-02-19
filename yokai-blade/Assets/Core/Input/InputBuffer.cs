using System.Collections.Generic;
using UnityEngine;

namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Manages input buffering for combat actions.
    /// Ensures buffered inputs replay consistently across frame rates.
    ///
    /// INVARIANT: Deflect always wins priority when multiple inputs buffered.
    /// INVARIANT: Buffered inputs replay consistently at 30/60/120 fps.
    /// </summary>
    public class InputBuffer
    {
        private readonly List<BufferedInput> _buffer = new List<BufferedInput>(4);
        private readonly InputConfig _config;

        /// <summary>
        /// Maximum buffer size to prevent memory issues.
        /// </summary>
        private const int MAX_BUFFER_SIZE = 8;

        public InputBuffer(InputConfig config)
        {
            _config = config;
        }

        /// <summary>
        /// Add an input to the buffer.
        /// Uses FixedTime for frame-rate independent timing.
        /// </summary>
        public void Buffer(InputAction action, float fixedTime)
        {
            if (!action.CanBuffer())
            {
                return;
            }

            float window = _config.GetBufferWindow(action);
            var input = new BufferedInput(action, fixedTime, window);

            // Check for duplicate action already in buffer
            // Replace if same action to update timestamp
            for (int i = 0; i < _buffer.Count; i++)
            {
                if (_buffer[i].Action == action)
                {
                    _buffer[i] = input;
                    return;
                }
            }

            // Add new input
            if (_buffer.Count >= MAX_BUFFER_SIZE)
            {
                // Remove oldest
                _buffer.RemoveAt(0);
            }

            _buffer.Add(input);
        }

        /// <summary>
        /// Get the highest priority valid input from buffer.
        /// Does NOT consume the input - call Consume() after processing.
        /// </summary>
        public InputAction Peek(float currentTime)
        {
            CleanExpired(currentTime);

            if (_buffer.Count == 0)
            {
                return InputAction.None;
            }

            // Find highest priority valid input
            InputAction best = InputAction.None;
            int bestPriority = -1;

            foreach (var input in _buffer)
            {
                if (input.IsValid(currentTime))
                {
                    int priority = input.Action.Priority();
                    if (priority > bestPriority)
                    {
                        best = input.Action;
                        bestPriority = priority;
                    }
                }
            }

            return best;
        }

        /// <summary>
        /// Consume (remove) a specific action from the buffer.
        /// Call after successfully processing an input.
        /// </summary>
        public bool Consume(InputAction action)
        {
            for (int i = _buffer.Count - 1; i >= 0; i--)
            {
                if (_buffer[i].Action == action)
                {
                    _buffer.RemoveAt(i);
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// Consume the highest priority input and return it.
        /// </summary>
        public InputAction ConsumeHighestPriority(float currentTime)
        {
            var action = Peek(currentTime);
            if (action != InputAction.None)
            {
                Consume(action);
            }
            return action;
        }

        /// <summary>
        /// Check if a specific action is buffered and valid.
        /// </summary>
        public bool HasBuffered(InputAction action, float currentTime)
        {
            foreach (var input in _buffer)
            {
                if (input.Action == action && input.IsValid(currentTime))
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// Clear all buffered inputs.
        /// </summary>
        public void Clear()
        {
            _buffer.Clear();
        }

        /// <summary>
        /// Number of currently buffered inputs.
        /// </summary>
        public int Count => _buffer.Count;

        /// <summary>
        /// Remove expired inputs from buffer.
        /// </summary>
        private void CleanExpired(float currentTime)
        {
            for (int i = _buffer.Count - 1; i >= 0; i--)
            {
                if (_buffer[i].IsExpired(currentTime))
                {
                    _buffer.RemoveAt(i);
                }
            }
        }

        /// <summary>
        /// Debug: Get all buffered inputs as string.
        /// </summary>
        public string DebugString(float currentTime)
        {
            if (_buffer.Count == 0) return "(empty)";

            var sb = new System.Text.StringBuilder();
            foreach (var input in _buffer)
            {
                if (input.IsValid(currentTime))
                {
                    sb.Append($"{input.Action}({input.TimeRemaining(currentTime):F2}s) ");
                }
            }
            return sb.ToString();
        }
    }
}
