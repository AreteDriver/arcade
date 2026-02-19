using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Units.Core;
using DustRTS.Units.Vehicles;
using DustRTS.Units.Infantry;
using DustRTS.Economy;

namespace DustRTS.Orbital
{
    /// <summary>
    /// Manages orbital strikes for all teams.
    /// </summary>
    public class OrbitalManager : MonoBehaviour
    {
        public static OrbitalManager Instance { get; private set; }

        [Header("Available Strikes")]
        [SerializeField] private OrbitalStrikeData[] availableStrikes;

        [Header("Settings")]
        [SerializeField] private float baseCooldownMultiplier = 1f;

        private Dictionary<Team, List<UplinkStation>> teamUplinks = new();
        private Dictionary<Team, Dictionary<OrbitalStrikeData, float>> strikeCooldowns = new();

        public IReadOnlyList<OrbitalStrikeData> AvailableStrikes => availableStrikes;

        public event Action<Team, OrbitalStrikeData> OnStrikeCalled;
        public event Action<Vector3, OrbitalStrikeData, Team> OnStrikeImpact;
        public event Action<Team, int> OnUplinkCountChanged;

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

        public void RegisterUplink(UplinkStation uplink, Team team)
        {
            if (team == null) return;

            if (!teamUplinks.ContainsKey(team))
            {
                teamUplinks[team] = new List<UplinkStation>();
            }

            if (!teamUplinks[team].Contains(uplink))
            {
                teamUplinks[team].Add(uplink);
                OnUplinkCountChanged?.Invoke(team, GetUplinkCount(team));
                Debug.Log($"[OrbitalManager] Team {team.TeamName} gained uplink. Total: {GetUplinkCount(team)}");
            }
        }

        public void UnregisterUplink(UplinkStation uplink, Team team)
        {
            if (team == null) return;

            if (teamUplinks.ContainsKey(team))
            {
                teamUplinks[team].Remove(uplink);
                OnUplinkCountChanged?.Invoke(team, GetUplinkCount(team));
                Debug.Log($"[OrbitalManager] Team {team.TeamName} lost uplink. Total: {GetUplinkCount(team)}");
            }
        }

        public int GetUplinkCount(Team team)
        {
            return teamUplinks.TryGetValue(team, out var uplinks) ? uplinks.Count : 0;
        }

        public float GetCooldownModifier(Team team)
        {
            int uplinks = GetUplinkCount(team);
            return uplinks switch
            {
                >= 3 => 0.6f,  // 40% faster cooldowns
                2 => 0.8f,     // 20% faster
                _ => 1f        // Normal
            };
        }

        public bool CanCallStrike(Team team, OrbitalStrikeData strikeData)
        {
            if (team == null || strikeData == null) return false;

            // Must have minimum uplinks
            int uplinks = GetUplinkCount(team);
            if (uplinks < strikeData.minUplinks) return false;

            // Check cooldown
            if (IsOnCooldown(team, strikeData)) return false;

            // Check resources
            var resourceManager = ServiceLocator.Get<ResourceManager>();
            if (resourceManager != null)
            {
                if (!resourceManager.CanAfford(team, 0, strikeData.iskCost)) return false;
            }

            return true;
        }

        public float GetCooldownRemaining(Team team, OrbitalStrikeData strikeData)
        {
            if (!strikeCooldowns.ContainsKey(team)) return 0f;
            if (!strikeCooldowns[team].ContainsKey(strikeData)) return 0f;

            return Mathf.Max(0f, strikeCooldowns[team][strikeData] - Time.time);
        }

        public bool IsOnCooldown(Team team, OrbitalStrikeData strikeData)
        {
            return GetCooldownRemaining(team, strikeData) > 0f;
        }

        public bool RequestStrike(Team team, OrbitalStrikeData strikeData, Vector3 targetPosition)
        {
            if (!CanCallStrike(team, strikeData))
            {
                Debug.LogWarning($"[OrbitalManager] Cannot call strike for {team?.TeamName}");
                return false;
            }

            // Deduct cost
            var resourceManager = ServiceLocator.Get<ResourceManager>();
            resourceManager?.SpendResources(team, 0, strikeData.iskCost);

            // Start cooldown
            if (!strikeCooldowns.ContainsKey(team))
            {
                strikeCooldowns[team] = new Dictionary<OrbitalStrikeData, float>();
            }

            float cooldown = strikeData.cooldown * GetCooldownModifier(team) * baseCooldownMultiplier;
            strikeCooldowns[team][strikeData] = Time.time + cooldown;

            // Start strike sequence
            StartCoroutine(ExecuteStrike(team, strikeData, targetPosition));

            OnStrikeCalled?.Invoke(team, strikeData);
            Debug.Log($"[OrbitalManager] {team.TeamName} called {strikeData.strikeName} at {targetPosition}");

            return true;
        }

        private IEnumerator ExecuteStrike(Team team, OrbitalStrikeData strikeData, Vector3 targetPosition)
        {
            // Spawn warning indicator
            GameObject warning = null;
            if (strikeData.warningIndicatorPrefab != null)
            {
                warning = Instantiate(strikeData.warningIndicatorPrefab, targetPosition, Quaternion.identity);

                // Scale to match strike radius
                if (strikeData.shape == StrikeShape.Circle)
                {
                    warning.transform.localScale = Vector3.one * strikeData.radius * 2f;
                }
            }

            // Play warning sound
            if (strikeData.warningSound != null)
            {
                AudioSource.PlayClipAtPoint(strikeData.warningSound, targetPosition);
            }

            // Wait for delay
            yield return new WaitForSeconds(strikeData.delay);

            // Remove warning
            if (warning != null)
            {
                Destroy(warning);
            }

            // Execute strike impact
            ApplyStrikeDamage(team, strikeData, targetPosition);

            // Spawn impact effect
            if (strikeData.impactEffectPrefab != null)
            {
                var impact = Instantiate(strikeData.impactEffectPrefab, targetPosition, Quaternion.identity);
                Destroy(impact, 5f);
            }

            // Play impact sound
            if (strikeData.impactSound != null)
            {
                AudioSource.PlayClipAtPoint(strikeData.impactSound, targetPosition, 1f);
            }

            // Spawn linger effect (radiation, etc.)
            if (strikeData.lingerEffectPrefab != null)
            {
                var linger = Instantiate(strikeData.lingerEffectPrefab, targetPosition, Quaternion.identity);
                Destroy(linger, strikeData.radiationDuration);
            }

            OnStrikeImpact?.Invoke(targetPosition, strikeData, team);
        }

        private void ApplyStrikeDamage(Team sourceTeam, OrbitalStrikeData strikeData, Vector3 center)
        {
            Collider[] hits;

            if (strikeData.shape == StrikeShape.Circle)
            {
                hits = Physics.OverlapSphere(center, strikeData.radius);
            }
            else // Line
            {
                // For line, we'll use a capsule cast approximation
                Vector3 halfExtent = new Vector3(strikeData.lineWidth, 10f, strikeData.lineLength / 2f);
                hits = Physics.OverlapBox(center, halfExtent);
            }

            foreach (var hit in hits)
            {
                var unit = hit.GetComponentInParent<Unit>();
                if (unit == null) continue;
                if (!unit.IsAlive) continue;

                // Check friendly fire
                if (!strikeData.friendlyFire && unit.Team == sourceTeam) continue;

                // Check if this strike type affects this unit
                bool canDamage = false;
                if (unit is Vehicle && strikeData.damageVehicles) canDamage = true;
                if (unit is InfantrySquad && strikeData.damageInfantry) canDamage = true;
                // Structures would be checked here too

                if (!canDamage) continue;

                // Calculate damage with falloff
                float distance = Vector3.Distance(center, unit.transform.position);
                float falloff = 1f - (distance / strikeData.radius);
                falloff = Mathf.Clamp01(falloff);

                int damage = Mathf.RoundToInt(strikeData.damage * falloff);

                // Apply damage
                unit.TakeDamage(damage, DamageType.HighExplosive, Vector3.down, null);

                // Apply EMP effect
                if (strikeData.disablesElectronics && unit is Vehicle vehicle)
                {
                    vehicle.Disable(strikeData.disableDuration);
                }
            }
        }

        public List<OrbitalStrikeData> GetAvailableStrikes(Team team)
        {
            var result = new List<OrbitalStrikeData>();
            int uplinks = GetUplinkCount(team);

            foreach (var strike in availableStrikes)
            {
                if (uplinks >= strike.minUplinks)
                {
                    result.Add(strike);
                }
            }

            return result;
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<OrbitalManager>();
            }
        }
    }
}
