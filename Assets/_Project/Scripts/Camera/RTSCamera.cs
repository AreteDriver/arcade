using UnityEngine;
using DustRTS.Core;
using DustRTS.Utility;

namespace DustRTS.Camera
{
    /// <summary>
    /// Main RTS camera controller.
    /// Handles panning, zooming, rotation, and bounds.
    /// </summary>
    public class RTSCamera : MonoBehaviour
    {
        public static RTSCamera Instance { get; private set; }

        [Header("Movement")]
        [SerializeField] private float panSpeed = 30f;
        [SerializeField] private float panAcceleration = 8f;
        [SerializeField] private float panDeceleration = 12f;
        [SerializeField] private float fastPanMultiplier = 2f;

        [Header("Edge Scrolling")]
        [SerializeField] private bool enableEdgeScroll = true;
        [SerializeField] private float edgeScrollThreshold = 20f;
        [SerializeField] private float edgeScrollSpeed = 25f;

        [Header("Middle Mouse Drag")]
        [SerializeField] private bool enableDragPan = true;
        [SerializeField] private float dragPanSpeed = 1.5f;

        [Header("Zoom")]
        [SerializeField] private float minHeight = 15f;
        [SerializeField] private float maxHeight = 80f;
        [SerializeField] private float zoomSpeed = 15f;
        [SerializeField] private float zoomSmoothing = 8f;

        [Header("Rotation")]
        [SerializeField] private bool enableRotation = true;
        [SerializeField] private float rotationSpeed = 90f;
        [SerializeField] private float rotationSmoothing = 8f;

        [Header("Camera Angle")]
        [SerializeField] private float minAngle = 45f;
        [SerializeField] private float maxAngle = 70f;

        [Header("Bounds")]
        [SerializeField] private bool enableBounds = true;
        [SerializeField] private Bounds cameraBounds = new(Vector3.zero, new Vector3(200f, 100f, 200f));

        [Header("Jump To")]
        [SerializeField] private float jumpDuration = 0.3f;

        // State
        private Vector3 currentVelocity;
        private float targetHeight;
        private float currentHeight;
        private float targetRotation;
        private float currentRotation;
        private Vector3 jumpStartPos;
        private Vector3 jumpTargetPos;
        private float jumpTimer;
        private bool isJumping;
        private bool isDragging;
        private Vector3 dragStartMousePos;
        private Vector3 dragStartCamPos;

        // Input cache
        private Vector2 moveInput;
        private float zoomInput;
        private float rotateInput;
        private bool fastMoveHeld;

        public float CurrentHeight => currentHeight;
        public float ZoomLevel => Mathf.InverseLerp(minHeight, maxHeight, currentHeight);

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            targetHeight = transform.position.y;
            currentHeight = targetHeight;
            targetRotation = transform.eulerAngles.y;
            currentRotation = targetRotation;
        }

        private void Start()
        {
            ServiceLocator.Register(this);
        }

        private void Update()
        {
            if (!IsInputAllowed()) return;

            GatherInput();
            HandleJump();
            HandlePanning();
            HandleDragPan();
            HandleZoom();
            HandleRotation();
            ApplyBounds();
            UpdateCameraAngle();
        }

        private bool IsInputAllowed()
        {
            var gameManager = ServiceLocator.Get<GameManager>();
            if (gameManager == null) return true;

            return gameManager.CurrentState == GameState.Playing;
        }

        private void GatherInput()
        {
            // Keyboard movement
            moveInput.x = Input.GetAxisRaw("Horizontal");
            moveInput.y = Input.GetAxisRaw("Vertical");

            // Zoom
            zoomInput = Input.GetAxis("Mouse ScrollWheel");

            // Rotation
            rotateInput = 0f;
            if (enableRotation)
            {
                if (Input.GetKey(KeyCode.Q)) rotateInput -= 1f;
                if (Input.GetKey(KeyCode.E)) rotateInput += 1f;
            }

            // Fast move
            fastMoveHeld = Input.GetKey(KeyCode.LeftShift);
        }

        private void HandlePanning()
        {
            if (isJumping || isDragging) return;

            Vector3 input = Vector3.zero;

            // Keyboard input
            input.x = moveInput.x;
            input.z = moveInput.y;

            // Edge scrolling
            if (enableEdgeScroll && Application.isFocused)
            {
                Vector2 mouse = Input.mousePosition;

                if (mouse.x >= 0 && mouse.x <= Screen.width &&
                    mouse.y >= 0 && mouse.y <= Screen.height)
                {
                    if (mouse.x < edgeScrollThreshold) input.x -= 1;
                    if (mouse.x > Screen.width - edgeScrollThreshold) input.x += 1;
                    if (mouse.y < edgeScrollThreshold) input.z -= 1;
                    if (mouse.y > Screen.height - edgeScrollThreshold) input.z += 1;
                }
            }

            // Normalize diagonal movement
            if (input.sqrMagnitude > 1f)
            {
                input.Normalize();
            }

            // Calculate target velocity
            float speed = panSpeed * (fastMoveHeld ? fastPanMultiplier : 1f);

            // Speed scales with zoom (faster when zoomed out)
            float zoomSpeedMultiplier = Mathf.Lerp(0.5f, 1.5f, ZoomLevel);
            speed *= zoomSpeedMultiplier;

            // Apply movement relative to camera rotation
            Vector3 forward = transform.forward.Flat().normalized;
            Vector3 right = transform.right.Flat().normalized;
            Vector3 targetVelocity = (forward * input.z + right * input.x) * speed;

            // Smooth acceleration/deceleration
            float smoothing = input.sqrMagnitude > 0.01f ? panAcceleration : panDeceleration;
            currentVelocity = Vector3.Lerp(currentVelocity, targetVelocity, smoothing * Time.deltaTime);

            transform.position += currentVelocity * Time.deltaTime;
        }

        private void HandleDragPan()
        {
            if (!enableDragPan) return;

            // Start drag
            if (Input.GetMouseButtonDown(2))
            {
                isDragging = true;
                dragStartMousePos = Input.mousePosition;
                dragStartCamPos = transform.position;
            }

            // End drag
            if (Input.GetMouseButtonUp(2))
            {
                isDragging = false;
            }

            // Update drag
            if (isDragging)
            {
                Vector3 mouseDelta = Input.mousePosition - dragStartMousePos;

                // Convert screen delta to world delta
                float heightFactor = currentHeight / 30f;
                Vector3 worldDelta = new Vector3(-mouseDelta.x, 0f, -mouseDelta.y) * dragPanSpeed * heightFactor * 0.01f;

                // Apply rotation
                worldDelta = Quaternion.Euler(0, transform.eulerAngles.y, 0) * worldDelta;

                transform.position = dragStartCamPos + worldDelta;
                currentVelocity = Vector3.zero;
            }
        }

        private void HandleZoom()
        {
            if (Mathf.Abs(zoomInput) > 0.01f)
            {
                targetHeight -= zoomInput * zoomSpeed * 10f;
                targetHeight = Mathf.Clamp(targetHeight, minHeight, maxHeight);
            }

            // Smooth zoom
            currentHeight = Mathf.Lerp(currentHeight, targetHeight, zoomSmoothing * Time.deltaTime);

            Vector3 pos = transform.position;
            pos.y = currentHeight;
            transform.position = pos;
        }

        private void HandleRotation()
        {
            if (!enableRotation) return;

            if (Mathf.Abs(rotateInput) > 0.01f)
            {
                targetRotation += rotateInput * rotationSpeed * Time.deltaTime;
            }

            // Smooth rotation
            currentRotation = Mathf.LerpAngle(currentRotation, targetRotation, rotationSmoothing * Time.deltaTime);

            transform.rotation = Quaternion.Euler(transform.eulerAngles.x, currentRotation, 0f);
        }

        private void UpdateCameraAngle()
        {
            // Adjust pitch based on zoom level (more top-down when zoomed out)
            float t = ZoomLevel;
            float angle = Mathf.Lerp(minAngle, maxAngle, t);

            Vector3 euler = transform.eulerAngles;
            euler.x = angle;
            transform.rotation = Quaternion.Euler(euler);
        }

        private void ApplyBounds()
        {
            if (!enableBounds) return;

            Vector3 pos = transform.position;
            pos.x = Mathf.Clamp(pos.x, cameraBounds.min.x, cameraBounds.max.x);
            pos.z = Mathf.Clamp(pos.z, cameraBounds.min.z, cameraBounds.max.z);
            transform.position = pos;
        }

        private void HandleJump()
        {
            if (!isJumping) return;

            jumpTimer += Time.deltaTime;
            float t = Mathf.Clamp01(jumpTimer / jumpDuration);

            // Ease out
            t = 1f - Mathf.Pow(1f - t, 3f);

            Vector3 pos = Vector3.Lerp(jumpStartPos, jumpTargetPos, t);
            pos.y = currentHeight;
            transform.position = pos;

            if (t >= 1f)
            {
                isJumping = false;
            }
        }

        public void JumpToPosition(Vector3 position)
        {
            jumpStartPos = transform.position;
            jumpTargetPos = position.WithY(transform.position.y);
            jumpTimer = 0f;
            isJumping = true;
            currentVelocity = Vector3.zero;
        }

        public void JumpToUnit(Transform target)
        {
            JumpToPosition(target.position);
        }

        public void SetBounds(Bounds bounds)
        {
            cameraBounds = bounds;
        }

        public void SetBoundsFromTerrain(Terrain terrain)
        {
            if (terrain == null) return;

            var terrainData = terrain.terrainData;
            var terrainPos = terrain.transform.position;

            cameraBounds = new Bounds(
                terrainPos + terrainData.size * 0.5f,
                terrainData.size
            );
        }

        public Ray ScreenPointToRay(Vector2 screenPoint)
        {
            return UnityEngine.Camera.main.ScreenPointToRay(screenPoint);
        }

        public Vector3 GetWorldPointOnGround(Vector2 screenPoint, LayerMask groundLayer)
        {
            Ray ray = ScreenPointToRay(screenPoint);
            if (Physics.Raycast(ray, out RaycastHit hit, 1000f, groundLayer))
            {
                return hit.point;
            }
            return Vector3.zero;
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<RTSCamera>();
            }
        }

        private void OnDrawGizmosSelected()
        {
            if (enableBounds)
            {
                Gizmos.color = new Color(0f, 1f, 0f, 0.3f);
                Gizmos.DrawWireCube(cameraBounds.center, cameraBounds.size);
            }
        }
    }
}
