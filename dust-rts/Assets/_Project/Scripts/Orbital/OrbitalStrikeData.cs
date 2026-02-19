using UnityEngine;
using DustRTS.Core;
using DustRTS.Units.Core;

namespace DustRTS.Orbital
{
    /// <summary>
    /// Data for an orbital strike type.
    /// </summary>
    [CreateAssetMenu(fileName = "Strike", menuName = "RTS/Orbital Strike")]
    public class OrbitalStrikeData : ScriptableObject
    {
        [Header("Identity")]
        public string strikeName = "Orbital Strike";
        [TextArea(2, 4)]
        public string description;
        public Sprite icon;

        [Header("Targeting")]
        public StrikeShape shape = StrikeShape.Circle;
        public float radius = 15f;
        public float lineLength = 100f;
        public float lineWidth = 10f;

        [Header("Timing")]
        public float delay = 5f;
        public float cooldown = 60f;

        [Header("Cost")]
        public int iskCost = 200;
        public int minUplinks = 1;

        [Header("Damage")]
        public int damage = 500;
        public bool damageVehicles = true;
        public bool damageInfantry = true;
        public bool damageStructures = true;
        public bool friendlyFire = false;

        [Header("Special Effects")]
        public bool disablesElectronics = false;
        public float disableDuration = 15f;
        public bool leavesRadiation = false;
        public float radiationDuration = 30f;

        [Header("Visuals")]
        public GameObject warningIndicatorPrefab;
        public GameObject impactEffectPrefab;
        public GameObject lingerEffectPrefab;

        [Header("Audio")]
        public AudioClip warningSound;
        public AudioClip impactSound;

        public float GetCooldownWithModifier(float modifier)
        {
            return cooldown * modifier;
        }
    }

    public enum StrikeShape
    {
        Circle,
        Line
    }
}
