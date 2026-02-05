using System.Collections.Generic;
using UnityEngine;

namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Central catalog mapping telegraph semantics to their VFX/SFX representations.
    ///
    /// INVARIANT: Each semantic maps to exactly one presentation.
    /// INVARIANT: This catalog is the single source of truth for telegraph meaning.
    /// INVARIANT: No runtime modifications allowed.
    /// </summary>
    [CreateAssetMenu(fileName = "TelegraphCatalog", menuName = "YokaiBlade/Telegraph Catalog")]
    public class TelegraphCatalog : ScriptableObject
    {
        [SerializeField]
        [Tooltip("All telegraph entries. Each semantic must appear exactly once.")]
        private List<TelegraphEntry> _entries = new List<TelegraphEntry>();

        private Dictionary<TelegraphSemantic, TelegraphEntry> _lookup;
        private bool _validated;

        /// <summary>
        /// Get the entry for a semantic. Returns null if not found.
        /// </summary>
        public TelegraphEntry GetEntry(TelegraphSemantic semantic)
        {
            EnsureLookup();

            if (_lookup.TryGetValue(semantic, out var entry))
            {
                return entry;
            }

            Debug.LogError($"[TelegraphCatalog] No entry for semantic: {semantic}");
            return null;
        }

        /// <summary>
        /// Check if a semantic has an entry in this catalog.
        /// </summary>
        public bool HasEntry(TelegraphSemantic semantic)
        {
            EnsureLookup();
            return _lookup.ContainsKey(semantic);
        }

        /// <summary>
        /// Validate the catalog. Called automatically on first access and in editor.
        /// </summary>
        public bool Validate(out List<string> errors)
        {
            errors = new List<string>();
            var seen = new HashSet<TelegraphSemantic>();

            foreach (var entry in _entries)
            {
                if (entry == null)
                {
                    errors.Add("Null entry in catalog");
                    continue;
                }

                if (!entry.Validate(out var entryError))
                {
                    errors.Add(entryError);
                    continue;
                }

                if (seen.Contains(entry.Semantic))
                {
                    errors.Add($"Duplicate semantic: {entry.Semantic}");
                    continue;
                }

                seen.Add(entry.Semantic);
            }

            // Check for missing semantics (excluding None)
            foreach (TelegraphSemantic semantic in System.Enum.GetValues(typeof(TelegraphSemantic)))
            {
                if (semantic != TelegraphSemantic.None && !seen.Contains(semantic))
                {
                    errors.Add($"Missing entry for semantic: {semantic}");
                }
            }

            _validated = errors.Count == 0;
            return _validated;
        }

        private void EnsureLookup()
        {
            if (_lookup != null) return;

            _lookup = new Dictionary<TelegraphSemantic, TelegraphEntry>();

            foreach (var entry in _entries)
            {
                if (entry != null && entry.Semantic != TelegraphSemantic.None)
                {
                    _lookup[entry.Semantic] = entry;
                }
            }
        }

        private void OnValidate()
        {
            _lookup = null; // Force rebuild on next access

            if (Validate(out var errors))
            {
                Debug.Log($"[TelegraphCatalog] Validation passed: {_entries.Count} entries");
            }
            else
            {
                foreach (var error in errors)
                {
                    Debug.LogWarning($"[TelegraphCatalog] {error}");
                }
            }
        }

        private void OnEnable()
        {
            _lookup = null;
        }
    }
}
