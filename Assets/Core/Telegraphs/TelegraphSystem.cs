using System;
using UnityEngine;

namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Central event bus for all telegraph emissions.
    ///
    /// INVARIANT: ALL telegraphs route through this system.
    /// INVARIANT: Semantic meaning is defined by catalog, never by caller.
    /// INVARIANT: No boss or attack can bypass this system.
    ///
    /// Usage:
    ///   TelegraphSystem.Emit(TelegraphSemantic.PerfectDeflectWindow, context);
    /// </summary>
    public class TelegraphSystem : MonoBehaviour
    {
        private static TelegraphSystem _instance;

        [SerializeField]
        [Tooltip("The catalog defining all telegraph semantics.")]
        private TelegraphCatalog _catalog;

        [SerializeField]
        [Tooltip("Audio source for telegraph sounds.")]
        private AudioSource _audioSource;

        [Header("Debug")]
        [SerializeField]
        private bool _logEmissions = true;

        /// <summary>
        /// Event fired when any telegraph is emitted.
        /// Subscribers receive the semantic and context.
        /// </summary>
        public static event Action<TelegraphSemantic, TelegraphContext> OnTelegraphEmitted;

        /// <summary>
        /// Last emitted semantic. Used for debug overlay.
        /// </summary>
        public static TelegraphSemantic LastSemantic { get; private set; }

        /// <summary>
        /// Last emission context. Used for debug overlay.
        /// </summary>
        public static TelegraphContext LastContext { get; private set; }

        /// <summary>
        /// Time of last emission (Time.time).
        /// </summary>
        public static float LastEmissionTime { get; private set; }

        /// <summary>
        /// Emit a telegraph with the given semantic and context.
        /// This is the ONLY way to emit telegraphs in the game.
        /// </summary>
        public static void Emit(TelegraphSemantic semantic, TelegraphContext context)
        {
            if (_instance == null)
            {
                Debug.LogError("[TelegraphSystem] Not initialized. Ensure TelegraphSystem exists in scene.");
                return;
            }

            _instance.EmitInternal(semantic, context);
        }

        /// <summary>
        /// Convenience overload for emitting from a transform.
        /// </summary>
        public static void Emit(TelegraphSemantic semantic, Transform source, string attackId = null)
        {
            Emit(semantic, TelegraphContext.FromTransform(source, attackId));
        }

        /// <summary>
        /// Convenience overload for world-position emission.
        /// </summary>
        public static void Emit(TelegraphSemantic semantic, Vector3 position, string attackId = null)
        {
            Emit(semantic, TelegraphContext.AtPosition(position, attackId));
        }

        private void EmitInternal(TelegraphSemantic semantic, TelegraphContext context)
        {
            if (semantic == TelegraphSemantic.None)
            {
                return;
            }

            var entry = _catalog.GetEntry(semantic);
            if (entry == null)
            {
                return;
            }

            // Update tracking
            LastSemantic = semantic;
            LastContext = context;
            LastEmissionTime = Time.time;

            // Spawn VFX
            if (entry.VfxPrefab != null)
            {
                SpawnVfx(entry, context);
            }

            // Play audio
            if (entry.AudioClip != null)
            {
                PlayAudio(entry, context);
            }

            // Notify subscribers
            OnTelegraphEmitted?.Invoke(semantic, context);

            // Debug logging
            if (_logEmissions)
            {
                Debug.Log($"[Telegraph] {semantic} at {context.Position:F1} (attack: {context.AttackId})");
            }
        }

        private void SpawnVfx(TelegraphEntry entry, TelegraphContext context)
        {
            var vfx = Instantiate(entry.VfxPrefab, context.Position, Quaternion.LookRotation(context.Direction));

            if (entry.AttachToSource && context.Source != null)
            {
                vfx.transform.SetParent(context.Source);
            }

            // Auto-destroy based on duration
            float duration = context.Duration > 0 ? context.Duration : entry.DefaultDuration;
            if (duration > 0)
            {
                Destroy(vfx, duration);
            }
        }

        private void PlayAudio(TelegraphEntry entry, TelegraphContext context)
        {
            if (_audioSource == null)
            {
                Debug.LogWarning("[TelegraphSystem] No audio source configured");
                return;
            }

            // TODO: Implement proper spatial audio and sidechaining
            // For now, use simple PlayOneShot
            _audioSource.PlayOneShot(entry.AudioClip, entry.Volume);
        }

        private void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Debug.LogError("[TelegraphSystem] Duplicate instance detected. Destroying.");
                Destroy(gameObject);
                return;
            }

            _instance = this;

            // Validate catalog on startup
            if (_catalog == null)
            {
                Debug.LogError("[TelegraphSystem] No catalog assigned!");
                return;
            }

            if (!_catalog.Validate(out var errors))
            {
                foreach (var error in errors)
                {
                    Debug.LogError($"[TelegraphSystem] Catalog error: {error}");
                }
            }
        }

        private void OnDestroy()
        {
            if (_instance == this)
            {
                _instance = null;
            }
        }

        /// <summary>
        /// Check if the system is ready to emit telegraphs.
        /// </summary>
        public static bool IsReady => _instance != null && _instance._catalog != null;
    }
}
