using System;
using UnityEngine;

namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Core player controller with deterministic update order.
    /// Processes buffered inputs and manages player state.
    ///
    /// INVARIANT: Update order is deterministic (FixedUpdate).
    /// INVARIANT: Deflect always wins priority.
    /// INVARIANT: Buffered inputs replay consistently across frame rates.
    /// </summary>
    [RequireComponent(typeof(PlayerInputHandler))]
    public class PlayerController : MonoBehaviour
    {
        [Header("Configuration")]
        [SerializeField]
        private InputConfig _inputConfig;

        [SerializeField]
        private float _moveSpeed = 5f;

        [Header("Debug")]
        [SerializeField]
        private bool _logStateChanges = true;

        private PlayerInputHandler _inputHandler;
        private CharacterController _characterController;
        private Rigidbody _rigidbody;

        private PlayerState _currentState = PlayerState.Idle;
        private float _stateTimer;
        private float _lastActionTime;

        /// <summary>
        /// Current player state.
        /// </summary>
        public PlayerState CurrentState => _currentState;

        /// <summary>
        /// Event fired when player state changes.
        /// </summary>
        public event Action<PlayerState, PlayerState> OnStateChanged;

        /// <summary>
        /// Event fired when a combat action is executed.
        /// </summary>
        public event Action<InputAction> OnActionExecuted;

        private void Awake()
        {
            _inputHandler = GetComponent<PlayerInputHandler>();
            _characterController = GetComponent<CharacterController>();
            _rigidbody = GetComponent<Rigidbody>();
        }

        /// <summary>
        /// FixedUpdate for deterministic input processing.
        /// All input consumption happens here for frame-rate independence.
        /// </summary>
        private void FixedUpdate()
        {
            float deltaTime = Time.fixedDeltaTime;
            float currentTime = Time.fixedTime;

            // Update state timer
            _stateTimer += deltaTime;

            // Process state-specific logic
            UpdateState(deltaTime);

            // Process buffered inputs
            ProcessBufferedInput(currentTime);

            // Handle movement
            if (_currentState.CanMove())
            {
                ProcessMovement(deltaTime);
            }
        }

        private void UpdateState(float deltaTime)
        {
            switch (_currentState)
            {
                case PlayerState.Attacking:
                    // Attack duration handled by combat system
                    break;

                case PlayerState.Deflecting:
                    // Deflect duration handled by combat system
                    break;

                case PlayerState.Dodging:
                    // Dodge duration handled by combat system
                    break;

                case PlayerState.Stunned:
                    // Stun duration handled by combat system
                    break;

                case PlayerState.Recovering:
                    // Auto-transition back to idle
                    // Recovery time set by combat system
                    break;
            }
        }

        private void ProcessBufferedInput(float currentTime)
        {
            // Check action cooldown
            if (currentTime - _lastActionTime < _inputConfig.ActionCooldown)
            {
                return;
            }

            // Get highest priority buffered action
            InputAction action = _inputHandler.Buffer.Peek(currentTime);

            if (action == InputAction.None)
            {
                return;
            }

            // Check if we can perform this action
            if (!_currentState.CanPerform(action))
            {
                // Special case: Deflect can cancel attack
                if (action == InputAction.Deflect && _currentState == PlayerState.Attacking)
                {
                    // Allow deflect cancel
                }
                else
                {
                    return;
                }
            }

            // Consume and execute
            _inputHandler.Buffer.Consume(action);
            ExecuteAction(action, currentTime);
        }

        private void ExecuteAction(InputAction action, float currentTime)
        {
            _lastActionTime = currentTime;

            switch (action)
            {
                case InputAction.Strike:
                    TransitionToState(PlayerState.Attacking);
                    break;

                case InputAction.Deflect:
                    TransitionToState(PlayerState.Deflecting);
                    break;

                case InputAction.Dodge:
                    TransitionToState(PlayerState.Dodging);
                    break;
            }

            OnActionExecuted?.Invoke(action);

            if (_logStateChanges)
            {
                Debug.Log($"[PlayerController] Executed: {action}");
            }
        }

        private void ProcessMovement(float deltaTime)
        {
            Vector2 input = _inputHandler.MoveInput;

            if (input.sqrMagnitude < 0.01f)
            {
                if (_currentState == PlayerState.Moving)
                {
                    TransitionToState(PlayerState.Idle);
                }
                return;
            }

            // Convert to world space movement
            Vector3 move = new Vector3(input.x, 0, input.y) * _moveSpeed * deltaTime;

            // Apply movement
            if (_characterController != null)
            {
                _characterController.Move(move);
            }
            else if (_rigidbody != null)
            {
                _rigidbody.MovePosition(_rigidbody.position + move);
            }
            else
            {
                transform.position += move;
            }

            if (_currentState == PlayerState.Idle)
            {
                TransitionToState(PlayerState.Moving);
            }
        }

        /// <summary>
        /// Transition to a new state. Called by this controller and combat systems.
        /// </summary>
        public void TransitionToState(PlayerState newState)
        {
            if (_currentState == newState)
            {
                return;
            }

            PlayerState oldState = _currentState;
            _currentState = newState;
            _stateTimer = 0f;

            // Clear buffer on certain transitions
            if (newState == PlayerState.Dead)
            {
                _inputHandler.ClearBuffer();
            }

            OnStateChanged?.Invoke(oldState, newState);

            if (_logStateChanges)
            {
                Debug.Log($"[PlayerController] State: {oldState} -> {newState}");
            }
        }

        /// <summary>
        /// Force transition to recovery state. Called by combat system after actions complete.
        /// </summary>
        public void EnterRecovery()
        {
            TransitionToState(PlayerState.Recovering);
        }

        /// <summary>
        /// Return to idle state. Called when recovery completes.
        /// </summary>
        public void ReturnToIdle()
        {
            if (_currentState == PlayerState.Recovering)
            {
                TransitionToState(PlayerState.Idle);
            }
        }

        /// <summary>
        /// Enter stun state. Called when player is hit.
        /// </summary>
        public void EnterStun()
        {
            TransitionToState(PlayerState.Stunned);
        }

        /// <summary>
        /// Kill the player.
        /// </summary>
        public void Die()
        {
            TransitionToState(PlayerState.Dead);
        }

        /// <summary>
        /// Revive the player.
        /// </summary>
        public void Revive()
        {
            if (_currentState == PlayerState.Dead)
            {
                TransitionToState(PlayerState.Idle);
            }
        }
    }
}
