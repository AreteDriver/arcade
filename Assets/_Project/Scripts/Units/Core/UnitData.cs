using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// ScriptableObject defining unit stats and properties.
    /// Create one per unit type.
    /// </summary>
    [CreateAssetMenu(fileName = "Unit", menuName = "RTS/Unit Data")]
    public class UnitData : ScriptableObject
    {
        [Header("Identity")]
        public string unitName = "Unit";
        [TextArea(2, 4)]
        public string description;
        public Sprite icon;
        public UnitType unitType = UnitType.Infantry;
        public FactionType faction = FactionType.Neutral;

        [Header("Prefab")]
        public GameObject prefab;

        [Header("Health")]
        public int maxHealth = 100;
        public float armor = 0f;
        public bool canRegenerate = false;
        public float regenPerSecond = 0f;

        [Header("Movement")]
        public float moveSpeed = 5f;
        public float rotationSpeed = 180f;
        public float acceleration = 20f;
        public float stoppingDistance = 0.5f;

        [Header("Vision")]
        public float sightRange = 30f;
        public bool canDetectStealth = false;

        [Header("Cost")]
        public int nanoPasteCost = 100;
        public int iskCost = 0;
        public float buildTime = 10f;

        [Header("Combat")]
        public WeaponSlot primaryWeapon;
        public WeaponSlot secondaryWeapon;
        public float suppressionResistance = 0f;

        [Header("Capabilities")]
        public bool canCapture = false;
        public bool canGarrison = false;
        public bool canTransport = false;
        public int transportCapacity = 0;
        public bool canRepair = false;
        public bool canHeal = false;

        [Header("Audio")]
        public AudioClip selectSound;
        public AudioClip moveSound;
        public AudioClip attackSound;
        public AudioClip deathSound;

        [Header("UI")]
        public float healthBarHeight = 2f;
        public float selectionRadius = 1f;

        public bool IsInfantry => unitType == UnitType.Infantry;
        public bool IsVehicle => unitType == UnitType.Vehicle;
        public bool IsAircraft => unitType == UnitType.Aircraft;
        public bool IsStructure => unitType == UnitType.Structure;

        public int TotalCost => nanoPasteCost + iskCost;
    }

    [System.Serializable]
    public class WeaponSlot
    {
        public WeaponData weapon;
        public Transform muzzlePoint;
    }

    public enum UnitType
    {
        Infantry,
        Vehicle,
        Aircraft,
        Structure
    }
}
