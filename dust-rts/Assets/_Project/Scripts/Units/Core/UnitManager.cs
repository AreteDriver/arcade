using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// Manages all units in the game.
    /// Tracks units by team, provides queries.
    /// </summary>
    public class UnitManager : MonoBehaviour
    {
        public static UnitManager Instance { get; private set; }

        private Dictionary<Team, List<Unit>> unitsByTeam = new();
        private List<Unit> allUnits = new();

        public IReadOnlyList<Unit> AllUnits => allUnits;
        public int TotalUnitCount => allUnits.Count;

        public event Action<Unit> OnUnitSpawned;
        public event Action<Unit> OnUnitKilled;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            ServiceLocator.Register(this);
        }

        public void RegisterUnit(Unit unit)
        {
            if (unit == null) return;
            if (allUnits.Contains(unit)) return;

            allUnits.Add(unit);

            var team = unit.Team;
            if (team != null)
            {
                if (!unitsByTeam.ContainsKey(team))
                {
                    unitsByTeam[team] = new List<Unit>();
                }
                unitsByTeam[team].Add(unit);
            }

            unit.OnKilled += HandleUnitKilled;
            OnUnitSpawned?.Invoke(unit);
        }

        public void UnregisterUnit(Unit unit)
        {
            if (unit == null) return;

            allUnits.Remove(unit);

            var team = unit.Team;
            if (team != null && unitsByTeam.ContainsKey(team))
            {
                unitsByTeam[team].Remove(unit);
            }

            unit.OnKilled -= HandleUnitKilled;
        }

        private void HandleUnitKilled(Unit unit)
        {
            OnUnitKilled?.Invoke(unit);
        }

        public List<Unit> GetUnitsForTeam(Team team)
        {
            if (team == null) return new List<Unit>();
            return unitsByTeam.TryGetValue(team, out var units)
                ? new List<Unit>(units.Where(u => u != null && u.IsAlive))
                : new List<Unit>();
        }

        public List<Unit> GetEnemyUnits(Team myTeam)
        {
            var enemies = new List<Unit>();

            foreach (var kvp in unitsByTeam)
            {
                if (kvp.Key.IsEnemy(myTeam))
                {
                    enemies.AddRange(kvp.Value.Where(u => u != null && u.IsAlive));
                }
            }

            return enemies;
        }

        public List<Unit> GetAllyUnits(Team myTeam)
        {
            var allies = new List<Unit>();

            foreach (var kvp in unitsByTeam)
            {
                if (kvp.Key.IsAlly(myTeam))
                {
                    allies.AddRange(kvp.Value.Where(u => u != null && u.IsAlive));
                }
            }

            return allies;
        }

        public List<Unit> GetUnitsInRadius(Vector3 center, float radius, Team team = null)
        {
            var result = new List<Unit>();
            float sqrRadius = radius * radius;

            foreach (var unit in allUnits)
            {
                if (unit == null || !unit.IsAlive) continue;
                if (team != null && unit.Team != team) continue;

                float sqrDistance = (unit.transform.position - center).sqrMagnitude;
                if (sqrDistance <= sqrRadius)
                {
                    result.Add(unit);
                }
            }

            return result;
        }

        public List<Unit> GetEnemyUnitsInRadius(Vector3 center, float radius, Team myTeam)
        {
            var result = new List<Unit>();
            float sqrRadius = radius * radius;

            foreach (var unit in allUnits)
            {
                if (unit == null || !unit.IsAlive) continue;
                if (!unit.Team.IsEnemy(myTeam)) continue;

                float sqrDistance = (unit.transform.position - center).sqrMagnitude;
                if (sqrDistance <= sqrRadius)
                {
                    result.Add(unit);
                }
            }

            return result;
        }

        public Unit GetNearestUnit(Vector3 position, Team team = null)
        {
            Unit nearest = null;
            float nearestSqrDistance = float.MaxValue;

            foreach (var unit in allUnits)
            {
                if (unit == null || !unit.IsAlive) continue;
                if (team != null && unit.Team != team) continue;

                float sqrDistance = (unit.transform.position - position).sqrMagnitude;
                if (sqrDistance < nearestSqrDistance)
                {
                    nearestSqrDistance = sqrDistance;
                    nearest = unit;
                }
            }

            return nearest;
        }

        public Unit GetNearestEnemy(Vector3 position, Team myTeam)
        {
            Unit nearest = null;
            float nearestSqrDistance = float.MaxValue;

            foreach (var unit in allUnits)
            {
                if (unit == null || !unit.IsAlive) continue;
                if (!unit.Team.IsEnemy(myTeam)) continue;

                float sqrDistance = (unit.transform.position - position).sqrMagnitude;
                if (sqrDistance < nearestSqrDistance)
                {
                    nearestSqrDistance = sqrDistance;
                    nearest = unit;
                }
            }

            return nearest;
        }

        public int GetUnitCount(Team team)
        {
            if (team == null) return 0;
            return unitsByTeam.TryGetValue(team, out var units)
                ? units.Count(u => u != null && u.IsAlive)
                : 0;
        }

        public int GetUnitCountByType(Team team, UnitType type)
        {
            if (team == null) return 0;
            if (!unitsByTeam.TryGetValue(team, out var units)) return 0;

            return units.Count(u => u != null && u.IsAlive && u.Data.unitType == type);
        }

        public void CleanupDeadUnits()
        {
            allUnits.RemoveAll(u => u == null || !u.IsAlive);

            foreach (var team in unitsByTeam.Keys.ToList())
            {
                unitsByTeam[team].RemoveAll(u => u == null || !u.IsAlive);
            }
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<UnitManager>();
            }
        }
    }
}
