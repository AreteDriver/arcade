using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using DustRTS.Utility;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// Handles unit movement and pathfinding via NavMesh.
    /// </summary>
    [RequireComponent(typeof(NavMeshAgent))]
    public class UnitMovement : MonoBehaviour
    {
        [Header("Movement")]
        [SerializeField] private float moveSpeed = 5f;
        [SerializeField] private float rotationSpeed = 180f;
        [SerializeField] private float acceleration = 20f;
        [SerializeField] private float stoppingDistance = 0.5f;

        [Header("Formation")]
        [SerializeField] private float formationSpacing = 2f;

        private NavMeshAgent agent;
        private Queue<Vector3> waypointQueue = new();
        private Vector3 currentDestination;
        private bool hasDestination;
        private bool isMoving;

        public float MoveSpeed => moveSpeed;
        public float RotationSpeed => rotationSpeed;
        public bool IsMoving => isMoving;
        public bool HasDestination => hasDestination;
        public Vector3 CurrentDestination => currentDestination;
        public Vector3 Velocity => agent != null ? agent.velocity : Vector3.zero;

        public event System.Action OnDestinationReached;
        public event System.Action OnMovementStarted;
        public event System.Action OnMovementStopped;

        private void Awake()
        {
            agent = GetComponent<NavMeshAgent>();
        }

        public void Initialize(UnitData data)
        {
            moveSpeed = data.moveSpeed;
            rotationSpeed = data.rotationSpeed;
            acceleration = data.acceleration;
            stoppingDistance = data.stoppingDistance;

            ConfigureAgent();
        }

        private void ConfigureAgent()
        {
            if (agent == null) return;

            agent.speed = moveSpeed;
            agent.angularSpeed = rotationSpeed;
            agent.acceleration = acceleration;
            agent.stoppingDistance = stoppingDistance;
            agent.autoBraking = true;
        }

        private void Update()
        {
            if (!hasDestination) return;

            UpdateMovementState();
        }

        private void UpdateMovementState()
        {
            if (agent == null || !agent.enabled) return;

            // Check if we've reached destination
            if (!agent.pathPending && agent.remainingDistance <= agent.stoppingDistance)
            {
                if (waypointQueue.Count > 0)
                {
                    // Move to next waypoint
                    Vector3 nextPoint = waypointQueue.Dequeue();
                    SetDestinationInternal(nextPoint);
                }
                else
                {
                    // Reached final destination
                    hasDestination = false;

                    if (isMoving)
                    {
                        isMoving = false;
                        OnMovementStopped?.Invoke();
                    }

                    OnDestinationReached?.Invoke();
                }
            }
            else
            {
                // Still moving
                if (!isMoving)
                {
                    isMoving = true;
                    OnMovementStarted?.Invoke();
                }
            }
        }

        public void SetDestination(Vector3 position)
        {
            waypointQueue.Clear();
            SetDestinationInternal(position);
        }

        public void QueueDestination(Vector3 position)
        {
            if (!hasDestination)
            {
                SetDestination(position);
            }
            else
            {
                waypointQueue.Enqueue(position);
            }
        }

        private void SetDestinationInternal(Vector3 position)
        {
            if (agent == null || !agent.enabled) return;

            // Sample position on NavMesh
            if (NavMesh.SamplePosition(position, out NavMeshHit hit, 5f, NavMesh.AllAreas))
            {
                position = hit.position;
            }

            currentDestination = position;
            hasDestination = true;
            agent.SetDestination(position);

            if (!isMoving)
            {
                isMoving = true;
                OnMovementStarted?.Invoke();
            }
        }

        public void Stop()
        {
            waypointQueue.Clear();
            hasDestination = false;

            if (agent != null && agent.enabled)
            {
                agent.ResetPath();
            }

            if (isMoving)
            {
                isMoving = false;
                OnMovementStopped?.Invoke();
            }
        }

        public void Pause()
        {
            if (agent != null && agent.enabled)
            {
                agent.isStopped = true;
            }
        }

        public void Resume()
        {
            if (agent != null && agent.enabled)
            {
                agent.isStopped = false;
            }
        }

        public void SetSpeed(float speed)
        {
            moveSpeed = speed;
            if (agent != null)
            {
                agent.speed = speed;
            }
        }

        public void SetSpeedMultiplier(float multiplier)
        {
            if (agent != null)
            {
                agent.speed = moveSpeed * multiplier;
            }
        }

        public void ResetSpeed()
        {
            if (agent != null)
            {
                agent.speed = moveSpeed;
            }
        }

        public void RotateTowards(Vector3 target, float speedMultiplier = 1f)
        {
            Vector3 direction = (target - transform.position).Flat();
            if (direction.sqrMagnitude < 0.001f) return;

            Quaternion targetRotation = Quaternion.LookRotation(direction);
            transform.rotation = Quaternion.RotateTowards(
                transform.rotation,
                targetRotation,
                rotationSpeed * speedMultiplier * Time.deltaTime
            );
        }

        public void LookAt(Vector3 target)
        {
            Vector3 direction = (target - transform.position).Flat();
            if (direction.sqrMagnitude > 0.001f)
            {
                transform.rotation = Quaternion.LookRotation(direction);
            }
        }

        public bool IsLookingAt(Vector3 target, float threshold = 10f)
        {
            Vector3 direction = (target - transform.position).Flat();
            if (direction.sqrMagnitude < 0.001f) return true;

            float angle = Vector3.Angle(transform.forward.Flat(), direction);
            return angle <= threshold;
        }

        public float GetDistanceTo(Vector3 position)
        {
            return Vector3.Distance(transform.position, position);
        }

        public bool IsWithinRange(Vector3 position, float range)
        {
            return GetDistanceTo(position) <= range;
        }

        public void Warp(Vector3 position)
        {
            if (agent != null && agent.enabled)
            {
                agent.Warp(position);
            }
            else
            {
                transform.position = position;
            }
        }

        public void EnableAgent()
        {
            if (agent != null)
            {
                agent.enabled = true;
            }
        }

        public void DisableAgent()
        {
            if (agent != null)
            {
                agent.enabled = false;
            }
        }

        public bool HasPath()
        {
            return agent != null && agent.hasPath;
        }

        public bool IsPathComplete()
        {
            if (agent == null) return true;
            if (!agent.hasPath) return true;
            return agent.remainingDistance <= agent.stoppingDistance;
        }

        private void OnDrawGizmosSelected()
        {
            if (!hasDestination) return;

            Gizmos.color = Color.green;
            Gizmos.DrawLine(transform.position, currentDestination);
            Gizmos.DrawWireSphere(currentDestination, 0.5f);

            // Draw queued waypoints
            Gizmos.color = Color.yellow;
            Vector3 prev = currentDestination;
            foreach (var waypoint in waypointQueue)
            {
                Gizmos.DrawLine(prev, waypoint);
                Gizmos.DrawWireSphere(waypoint, 0.3f);
                prev = waypoint;
            }
        }
    }
}
