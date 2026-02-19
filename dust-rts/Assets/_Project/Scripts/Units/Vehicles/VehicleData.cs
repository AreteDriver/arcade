using UnityEngine;
using DustRTS.Units.Core;

namespace DustRTS.Units.Vehicles
{
    /// <summary>
    /// Extended data for vehicles.
    /// </summary>
    [CreateAssetMenu(fileName = "Vehicle", menuName = "RTS/Vehicle Data")]
    public class VehicleData : UnitData
    {
        [Header("Vehicle Armor")]
        public float frontArmor = 100f;
        public float sideArmor = 60f;
        public float rearArmor = 30f;

        [Header("Turret")]
        public bool hasTurret = true;
        public float turretRotationSpeed = 90f;

        [Header("Transport")]
        public new int transportCapacity = 0;
        public bool isSpawnPoint = false;

        [Header("Special")]
        public bool canSiegeMode = false;
        public float siegeModeRangeBonus = 1.5f;
        public float siegeModeDamageBonus = 1.25f;

        private void OnValidate()
        {
            unitType = UnitType.Vehicle;
        }
    }
}
