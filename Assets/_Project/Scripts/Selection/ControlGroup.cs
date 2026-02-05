using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace DustRTS.Selection
{
    /// <summary>
    /// Manages control groups (Ctrl+1-9 to assign, 1-9 to select).
    /// </summary>
    public class ControlGroup
    {
        private List<Selectable> members = new();
        private int groupNumber;

        public int GroupNumber => groupNumber;
        public IReadOnlyList<Selectable> Members => members;
        public int Count => members.Count;
        public bool IsEmpty => members.Count == 0;

        public ControlGroup(int number)
        {
            groupNumber = number;
        }

        public void SetMembers(IEnumerable<Selectable> selectables)
        {
            members.Clear();
            members.AddRange(selectables.Where(s => s != null));
        }

        public void AddMembers(IEnumerable<Selectable> selectables)
        {
            foreach (var s in selectables)
            {
                if (s != null && !members.Contains(s))
                {
                    members.Add(s);
                }
            }
        }

        public void Clear()
        {
            members.Clear();
        }

        public void RemoveDestroyed()
        {
            members.RemoveAll(m => m == null);
        }

        public Vector3 GetCenterPosition()
        {
            RemoveDestroyed();

            if (members.Count == 0) return Vector3.zero;

            Vector3 sum = Vector3.zero;
            foreach (var m in members)
            {
                sum += m.transform.position;
            }
            return sum / members.Count;
        }

        public List<Selectable> GetAliveMembers()
        {
            RemoveDestroyed();
            return new List<Selectable>(members);
        }
    }

    /// <summary>
    /// Manages all control groups for a player.
    /// </summary>
    public class ControlGroupManager
    {
        private Dictionary<int, ControlGroup> groups = new();

        public ControlGroupManager()
        {
            // Initialize groups 1-9 (and 0)
            for (int i = 0; i <= 9; i++)
            {
                groups[i] = new ControlGroup(i);
            }
        }

        public ControlGroup GetGroup(int number)
        {
            return groups.TryGetValue(number, out var group) ? group : null;
        }

        public void AssignGroup(int number, IEnumerable<Selectable> selectables, bool additive = false)
        {
            var group = GetGroup(number);
            if (group == null) return;

            if (additive)
            {
                group.AddMembers(selectables);
            }
            else
            {
                group.SetMembers(selectables);
            }

            Debug.Log($"[ControlGroup] Group {number} now has {group.Count} members");
        }

        public void ClearGroup(int number)
        {
            GetGroup(number)?.Clear();
        }

        public void ClearAll()
        {
            foreach (var group in groups.Values)
            {
                group.Clear();
            }
        }

        public void CleanupDestroyed()
        {
            foreach (var group in groups.Values)
            {
                group.RemoveDestroyed();
            }
        }
    }
}
