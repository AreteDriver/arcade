using System;
using UnityEngine;
using UnityEngine.InputSystem;

namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Bridges Unity Input System to the game's input buffer.
    /// Reads raw input and feeds it into the buffer for processing.
    ///
    /// This component should be on the Player GameObject.
    /// Requires Unity Input System package.
    /// </summary>
    [RequireComponent(typeof(PlayerInput))]
    public class PlayerInputHandler : MonoBehaviour
    {
        [SerializeField]
        private InputConfig _config;

        private InputBuffer _buffer;
        private PlayerInput _playerInput;

        private Vector2 _moveInput;
        private bool _moveInputActive;

        /// <summary>
        /// Current movement input vector (normalized).
        /// </summary>
        public Vector2 MoveInput => _moveInputActive ? _moveInput : Vector2.zero;

        /// <summary>
        /// Access to the input buffer for consuming inputs.
        /// </summary>
        public InputBuffer Buffer => _buffer;

        /// <summary>
        /// Event fired when any combat action is pressed.
        /// </summary>
        public event Action<InputAction> OnActionPressed;

        private void Awake()
        {
            _playerInput = GetComponent<PlayerInput>();

            if (_config == null)
            {
                Debug.LogError("[PlayerInputHandler] No InputConfig assigned!");
                _config = ScriptableObject.CreateInstance<InputConfig>();
            }

            _buffer = new InputBuffer(_config);
        }

        private void OnEnable()
        {
            // Subscribe to input actions
            var actions = _playerInput.actions;

            var moveAction = actions.FindAction("Move");
            var dodgeAction = actions.FindAction("Dodge");
            var deflectAction = actions.FindAction("Deflect");
            var strikeAction = actions.FindAction("Strike");

            if (moveAction != null)
            {
                moveAction.performed += OnMove;
                moveAction.canceled += OnMoveCanceled;
            }

            if (dodgeAction != null)
            {
                dodgeAction.performed += OnDodge;
            }

            if (deflectAction != null)
            {
                deflectAction.performed += OnDeflect;
            }

            if (strikeAction != null)
            {
                strikeAction.performed += OnStrike;
            }
        }

        private void OnDisable()
        {
            var actions = _playerInput?.actions;
            if (actions == null) return;

            var moveAction = actions.FindAction("Move");
            var dodgeAction = actions.FindAction("Dodge");
            var deflectAction = actions.FindAction("Deflect");
            var strikeAction = actions.FindAction("Strike");

            if (moveAction != null)
            {
                moveAction.performed -= OnMove;
                moveAction.canceled -= OnMoveCanceled;
            }

            if (dodgeAction != null)
            {
                dodgeAction.performed -= OnDodge;
            }

            if (deflectAction != null)
            {
                deflectAction.performed -= OnDeflect;
            }

            if (strikeAction != null)
            {
                strikeAction.performed -= OnStrike;
            }
        }

        #region Input Callbacks

        private void OnMove(InputAction.CallbackContext context)
        {
            _moveInput = context.ReadValue<Vector2>();
            _moveInputActive = _moveInput.sqrMagnitude > 0.01f;
        }

        private void OnMoveCanceled(InputAction.CallbackContext context)
        {
            _moveInput = Vector2.zero;
            _moveInputActive = false;
        }

        private void OnDodge(InputAction.CallbackContext context)
        {
            BufferAction(Input.InputAction.Dodge);
        }

        private void OnDeflect(InputAction.CallbackContext context)
        {
            BufferAction(Input.InputAction.Deflect);
        }

        private void OnStrike(InputAction.CallbackContext context)
        {
            BufferAction(Input.InputAction.Strike);
        }

        #endregion

        private void BufferAction(InputAction action)
        {
            // Use FixedTime for frame-rate independent buffering
            _buffer.Buffer(action, Time.fixedTime);
            OnActionPressed?.Invoke(action);
        }

        /// <summary>
        /// Clear the input buffer. Call on state transitions.
        /// </summary>
        public void ClearBuffer()
        {
            _buffer.Clear();
        }

        /// <summary>
        /// Get the highest priority buffered action.
        /// </summary>
        public InputAction GetBufferedAction()
        {
            return _buffer.Peek(Time.fixedTime);
        }

        /// <summary>
        /// Consume and return the highest priority buffered action.
        /// </summary>
        public InputAction ConsumeBufferedAction()
        {
            return _buffer.ConsumeHighestPriority(Time.fixedTime);
        }
    }
}
