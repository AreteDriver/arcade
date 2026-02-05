using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Camera
{
    /// <summary>
    /// Minimap camera that renders from above.
    /// Also handles minimap click-to-move camera.
    /// </summary>
    [RequireComponent(typeof(UnityEngine.Camera))]
    public class MinimapCamera : MonoBehaviour
    {
        public static MinimapCamera Instance { get; private set; }

        [Header("Setup")]
        [SerializeField] private UnityEngine.Camera minimapCamera;
        [SerializeField] private RenderTexture minimapTexture;

        [Header("Position")]
        [SerializeField] private float height = 100f;
        [SerializeField] private Vector3 centerOffset = Vector3.zero;

        [Header("Size")]
        [SerializeField] private float orthographicSize = 100f;
        [SerializeField] private bool autoSizeFromBounds = true;

        [Header("Minimap Rect (for click detection)")]
        [SerializeField] private RectTransform minimapRect;

        private Bounds mapBounds;

        public UnityEngine.Camera Camera => minimapCamera;
        public RenderTexture Texture => minimapTexture;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            if (minimapCamera == null)
            {
                minimapCamera = GetComponent<UnityEngine.Camera>();
            }

            SetupCamera();
        }

        private void Start()
        {
            ServiceLocator.Register(this);
        }

        private void SetupCamera()
        {
            minimapCamera.orthographic = true;
            minimapCamera.orthographicSize = orthographicSize;
            minimapCamera.clearFlags = CameraClearFlags.SolidColor;
            minimapCamera.backgroundColor = new Color(0.1f, 0.1f, 0.1f, 1f);

            // Look straight down
            transform.rotation = Quaternion.Euler(90f, 0f, 0f);

            if (minimapTexture != null)
            {
                minimapCamera.targetTexture = minimapTexture;
            }
        }

        public void SetBounds(Bounds bounds)
        {
            mapBounds = bounds;

            // Position camera above center
            Vector3 pos = bounds.center + centerOffset;
            pos.y = height;
            transform.position = pos;

            // Auto-size to fit bounds
            if (autoSizeFromBounds)
            {
                float maxDimension = Mathf.Max(bounds.size.x, bounds.size.z);
                orthographicSize = maxDimension * 0.5f;
                minimapCamera.orthographicSize = orthographicSize;
            }
        }

        public void SetBoundsFromTerrain(Terrain terrain)
        {
            if (terrain == null) return;

            var data = terrain.terrainData;
            var pos = terrain.transform.position;

            var bounds = new Bounds(
                pos + data.size * 0.5f,
                data.size
            );

            SetBounds(bounds);
        }

        private void Update()
        {
            HandleMinimapClick();
        }

        private void HandleMinimapClick()
        {
            if (minimapRect == null) return;

            // Check if clicking on minimap
            if (Input.GetMouseButtonDown(0) || Input.GetMouseButton(0))
            {
                Vector2 mousePos = Input.mousePosition;

                if (RectTransformUtility.RectangleContainsScreenPoint(minimapRect, mousePos))
                {
                    Vector2 localPoint;
                    if (RectTransformUtility.ScreenPointToLocalPointInRectangle(
                        minimapRect, mousePos, null, out localPoint))
                    {
                        // Convert to normalized coordinates (0-1)
                        Rect rect = minimapRect.rect;
                        float normalizedX = (localPoint.x - rect.xMin) / rect.width;
                        float normalizedY = (localPoint.y - rect.yMin) / rect.height;

                        // Convert to world position
                        Vector3 worldPos = MinimapToWorld(normalizedX, normalizedY);

                        // Move main camera
                        if (Input.GetMouseButtonDown(0))
                        {
                            RTSCamera.Instance?.JumpToPosition(worldPos);
                        }
                    }
                }
            }
        }

        public Vector3 MinimapToWorld(float normalizedX, float normalizedY)
        {
            float worldX = Mathf.Lerp(mapBounds.min.x, mapBounds.max.x, normalizedX);
            float worldZ = Mathf.Lerp(mapBounds.min.z, mapBounds.max.z, normalizedY);

            return new Vector3(worldX, 0f, worldZ);
        }

        public Vector2 WorldToMinimap(Vector3 worldPos)
        {
            float normalizedX = Mathf.InverseLerp(mapBounds.min.x, mapBounds.max.x, worldPos.x);
            float normalizedY = Mathf.InverseLerp(mapBounds.min.z, mapBounds.max.z, worldPos.z);

            return new Vector2(normalizedX, normalizedY);
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<MinimapCamera>();
            }
        }
    }
}
