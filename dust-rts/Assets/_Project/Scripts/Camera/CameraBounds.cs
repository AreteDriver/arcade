using UnityEngine;

namespace DustRTS.Camera
{
    /// <summary>
    /// Defines camera boundaries for a map.
    /// Attach to a map object to auto-configure camera bounds.
    /// </summary>
    public class CameraBounds : MonoBehaviour
    {
        [SerializeField] private Vector3 boundsSize = new(200f, 100f, 200f);
        [SerializeField] private Vector3 boundsOffset = Vector3.zero;
        [SerializeField] private bool autoSetOnStart = true;
        [SerializeField] private bool useTerrainBounds = false;
        [SerializeField] private Terrain terrain;
        [SerializeField] private float padding = 10f;

        public Bounds Bounds
        {
            get
            {
                if (useTerrainBounds && terrain != null)
                {
                    return GetTerrainBounds();
                }
                return new Bounds(transform.position + boundsOffset, boundsSize);
            }
        }

        private void Start()
        {
            if (autoSetOnStart)
            {
                ApplyToCamera();
            }
        }

        public void ApplyToCamera()
        {
            var camera = RTSCamera.Instance;
            if (camera != null)
            {
                camera.SetBounds(Bounds);
            }
        }

        private Bounds GetTerrainBounds()
        {
            var data = terrain.terrainData;
            var pos = terrain.transform.position;

            Vector3 center = pos + data.size * 0.5f;
            Vector3 size = data.size;

            // Apply padding
            size.x -= padding * 2f;
            size.z -= padding * 2f;

            return new Bounds(center, size);
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0f, 1f, 0f, 0.5f);
            Gizmos.DrawWireCube(Bounds.center, Bounds.size);
        }
    }
}
