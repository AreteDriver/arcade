using System;
using UnityEngine;

namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Defines the VFX and SFX associated with a telegraph semantic.
    /// This mapping is immutable at runtime - semantics never change meaning.
    /// </summary>
    [Serializable]
    public class TelegraphEntry
    {
        [Tooltip("The semantic this entry defines. Must be unique in the catalog.")]
        public TelegraphSemantic Semantic;

        [Header("Visual")]
        [Tooltip("VFX prefab to spawn. Null means no visual.")]
        public GameObject VfxPrefab;

        [Tooltip("Default duration in seconds. Zero means instantaneous (1 frame).")]
        [Min(0f)]
        public float DefaultDuration;

        [Header("Audio")]
        [Tooltip("Audio clip to play. Null means no audio.")]
        public AudioClip AudioClip;

        [Tooltip("Volume multiplier for this telegraph.")]
        [Range(0f, 1f)]
        public float Volume = 1f;

        [Tooltip("Priority for audio mixing. Higher = more important.")]
        [Range(0, 10)]
        public int AudioPriority = 5;

        [Header("Behavior")]
        [Tooltip("If true, this telegraph sidechains (ducks) music and ambience.")]
        public bool SidechainAudio;

        [Tooltip("If true, VFX follows the source transform.")]
        public bool AttachToSource;

        /// <summary>
        /// Validate this entry has required data.
        /// </summary>
        public bool Validate(out string error)
        {
            if (Semantic == TelegraphSemantic.None)
            {
                error = "Entry has None semantic";
                return false;
            }

            if (VfxPrefab == null && AudioClip == null)
            {
                error = $"Entry for {Semantic} has no VFX or audio";
                return false;
            }

            error = null;
            return true;
        }
    }
}
