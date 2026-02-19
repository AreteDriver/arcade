using System.Collections.Generic;
using UnityEngine;

namespace YokaiBlade.Core.Combat
{
    public static class AttackValidator
    {
        public static bool ValidateAll(IEnumerable<AttackDefinition> attacks, out List<string> errors)
        {
            errors = new List<string>();
            var ids = new HashSet<string>();

            foreach (var attack in attacks)
            {
                if (attack == null)
                {
                    errors.Add("Null attack in collection");
                    continue;
                }
                if (!attack.Validate(out var error))
                {
                    errors.Add($"{attack.name}: {error}");
                    continue;
                }
                if (ids.Contains(attack.AttackId))
                {
                    errors.Add($"Duplicate AttackId: {attack.AttackId}");
                    continue;
                }
                ids.Add(attack.AttackId);
            }

            return errors.Count == 0;
        }
    }
}
