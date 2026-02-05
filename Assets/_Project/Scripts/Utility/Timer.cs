using System;
using UnityEngine;

namespace DustRTS.Utility
{
    /// <summary>
    /// Simple timer utility for cooldowns and delays.
    /// </summary>
    [Serializable]
    public class Timer
    {
        [SerializeField] private float duration;
        private float endTime;
        private bool isRunning;

        public float Duration => duration;
        public float Remaining => isRunning ? Mathf.Max(0, endTime - Time.time) : 0f;
        public float Progress => isRunning ? 1f - (Remaining / duration) : (duration > 0 ? 1f : 0f);
        public bool IsRunning => isRunning && Time.time < endTime;
        public bool IsComplete => !isRunning || Time.time >= endTime;

        public Timer(float duration)
        {
            this.duration = duration;
            isRunning = false;
        }

        public void Start()
        {
            endTime = Time.time + duration;
            isRunning = true;
        }

        public void Start(float customDuration)
        {
            duration = customDuration;
            Start();
        }

        public void Stop()
        {
            isRunning = false;
        }

        public void Reset()
        {
            Stop();
        }

        public bool TryComplete()
        {
            if (IsComplete)
            {
                Stop();
                return true;
            }
            return false;
        }

        public void SetDuration(float newDuration)
        {
            duration = newDuration;
        }
    }

    /// <summary>
    /// Cooldown timer that auto-resets.
    /// </summary>
    [Serializable]
    public class Cooldown
    {
        [SerializeField] private float duration;
        private float readyTime;

        public float Duration => duration;
        public float Remaining => Mathf.Max(0, readyTime - Time.time);
        public float Progress => duration > 0 ? 1f - (Remaining / duration) : 1f;
        public bool IsReady => Time.time >= readyTime;

        public Cooldown(float duration)
        {
            this.duration = duration;
            readyTime = 0f;
        }

        public bool TryUse()
        {
            if (IsReady)
            {
                readyTime = Time.time + duration;
                return true;
            }
            return false;
        }

        public void Use()
        {
            readyTime = Time.time + duration;
        }

        public void Reset()
        {
            readyTime = 0f;
        }

        public void SetDuration(float newDuration)
        {
            duration = newDuration;
        }

        public void ReduceCooldown(float amount)
        {
            readyTime = Mathf.Max(Time.time, readyTime - amount);
        }
    }
}
