using System.Collections.Generic;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Units.Core;
using DustRTS.Units.Infantry;

namespace DustRTS.Units.Vehicles
{
    /// <summary>
    /// Base class for vehicles - tanks, APCs, etc.
    /// Handles armor facing, turret rotation, and transport.
    /// </summary>
    public class Vehicle : Unit
    {
        [Header("Vehicle")]
        [SerializeField] protected VehicleData vehicleData;

        [Header("Turret")]
        [SerializeField] protected Transform turret;
        [SerializeField] protected float turretRotationSpeed = 90f;

        [Header("Armor Facing")]
        [SerializeField] protected float frontArmor = 100f;
        [SerializeField] protected float sideArmor = 60f;
        [SerializeField] protected float rearArmor = 30f;

        [Header("Transport")]
        [SerializeField] protected Transform[] passengerSlots;
        [SerializeField] protected Transform unloadPoint;

        protected List<InfantrySquad> passengers = new();
        protected bool isDisabled;
        protected float disableEndTime;

        public VehicleData VehicleData => vehicleData;
        public bool CanTransport => vehicleData != null && vehicleData.transportCapacity > 0;
        public int TransportCapacity => vehicleData?.transportCapacity ?? 0;
        public int PassengerCount => passengers.Count;
        public int RemainingCapacity => TransportCapacity - PassengerCount;
        public bool HasPassengers => passengers.Count > 0;
        public bool IsDisabled => isDisabled;
        public IReadOnlyList<InfantrySquad> Passengers => passengers;

        public float FrontArmor => vehicleData?.frontArmor ?? frontArmor;
        public float SideArmor => vehicleData?.sideArmor ?? sideArmor;
        public float RearArmor => vehicleData?.rearArmor ?? rearArmor;

        public override void Initialize(Team team)
        {
            base.Initialize(team);

            if (vehicleData != null)
            {
                frontArmor = vehicleData.frontArmor;
                sideArmor = vehicleData.sideArmor;
                rearArmor = vehicleData.rearArmor;
            }
        }

        protected override void Update()
        {
            if (!IsAlive) return;

            UpdateDisabledState();

            if (isDisabled)
            {
                // Can't do anything while disabled
                return;
            }

            base.Update();
            UpdateTurret();
        }

        protected virtual void UpdateTurret()
        {
            if (turret == null) return;
            if (currentTarget == null) return;

            Vector3 direction = currentTarget.transform.position - turret.position;
            direction.y = 0;

            if (direction.sqrMagnitude < 0.01f) return;

            Quaternion targetRotation = Quaternion.LookRotation(direction);
            turret.rotation = Quaternion.RotateTowards(
                turret.rotation,
                targetRotation,
                turretRotationSpeed * Time.deltaTime
            );
        }

        protected override void TryAttack()
        {
            if (currentTarget == null) return;
            if (turret == null)
            {
                base.TryAttack();
                return;
            }

            // Check if turret is facing target
            Vector3 toTarget = (currentTarget.transform.position - turret.position).normalized;
            toTarget.y = 0;
            float angle = Vector3.Angle(turret.forward, toTarget);

            if (angle < 15f)
            {
                base.TryAttack();
            }
        }

        public float GetArmorForAngle(Vector3 hitDirection)
        {
            // Calculate angle from vehicle's forward
            Vector3 flatDirection = hitDirection;
            flatDirection.y = 0;
            flatDirection.Normalize();

            float angle = Vector3.Angle(transform.forward, flatDirection);

            if (angle < 45f) return FrontArmor;
            if (angle > 135f) return RearArmor;
            return SideArmor;
        }

        // Transport
        public bool LoadSquad(InfantrySquad squad)
        {
            if (!CanTransport) return false;
            if (RemainingCapacity <= 0) return false;
            if (squad == null) return false;
            if (passengers.Contains(squad)) return false;

            passengers.Add(squad);
            squad.gameObject.SetActive(false);

            Debug.Log($"[Vehicle] {name} loaded {squad.name}. Passengers: {PassengerCount}/{TransportCapacity}");
            return true;
        }

        public void UnloadAll()
        {
            Vector3 unloadPos = unloadPoint != null ? unloadPoint.position : transform.position + transform.right * 3f;

            foreach (var squad in passengers)
            {
                if (squad != null)
                {
                    squad.gameObject.SetActive(true);
                    squad.transform.position = unloadPos + Random.insideUnitSphere.normalized * 2f;
                }
            }

            passengers.Clear();
            Debug.Log($"[Vehicle] {name} unloaded all passengers");
        }

        public void UnloadOne()
        {
            if (passengers.Count == 0) return;

            var squad = passengers[passengers.Count - 1];
            passengers.RemoveAt(passengers.Count - 1);

            if (squad != null)
            {
                Vector3 unloadPos = unloadPoint != null ? unloadPoint.position : transform.position + transform.right * 3f;
                squad.gameObject.SetActive(true);
                squad.transform.position = unloadPos;
            }
        }

        // Disable (EMP, etc.)
        public void Disable(float duration)
        {
            isDisabled = true;
            disableEndTime = Time.time + duration;
            movement.Stop();

            Debug.Log($"[Vehicle] {name} disabled for {duration} seconds");
        }

        protected void UpdateDisabledState()
        {
            if (isDisabled && Time.time >= disableEndTime)
            {
                isDisabled = false;
                Debug.Log($"[Vehicle] {name} systems restored");
            }
        }

        protected override void HandleDeath()
        {
            // Unload passengers before destruction (they might survive)
            if (HasPassengers)
            {
                UnloadAll();

                // Deal damage to ejected passengers
                // TODO: Implement
            }

            base.HandleDeath();
        }
    }
}
