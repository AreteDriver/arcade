using System.Collections.Generic;
using UnityEngine;

namespace DustRTS.Utility
{
    public static class Extensions
    {
        // Vector3 extensions
        public static Vector3 Flat(this Vector3 v)
        {
            return new Vector3(v.x, 0f, v.z);
        }

        public static Vector3 WithY(this Vector3 v, float y)
        {
            return new Vector3(v.x, y, v.z);
        }

        public static Vector2 ToVector2XZ(this Vector3 v)
        {
            return new Vector2(v.x, v.z);
        }

        public static Vector3 ToVector3XZ(this Vector2 v, float y = 0f)
        {
            return new Vector3(v.x, y, v.y);
        }

        // Collection extensions
        public static T GetRandom<T>(this IList<T> list)
        {
            if (list == null || list.Count == 0) return default;
            return list[Random.Range(0, list.Count)];
        }

        public static void Shuffle<T>(this IList<T> list)
        {
            int n = list.Count;
            while (n > 1)
            {
                n--;
                int k = Random.Range(0, n + 1);
                (list[k], list[n]) = (list[n], list[k]);
            }
        }

        // Transform extensions
        public static void LookAtFlat(this Transform transform, Vector3 target)
        {
            var direction = (target - transform.position).Flat();
            if (direction.sqrMagnitude > 0.001f)
            {
                transform.rotation = Quaternion.LookRotation(direction);
            }
        }

        public static void LookAtFlatSmooth(this Transform transform, Vector3 target, float rotationSpeed)
        {
            var direction = (target - transform.position).Flat();
            if (direction.sqrMagnitude > 0.001f)
            {
                var targetRotation = Quaternion.LookRotation(direction);
                transform.rotation = Quaternion.RotateTowards(
                    transform.rotation,
                    targetRotation,
                    rotationSpeed * Time.deltaTime
                );
            }
        }

        // LayerMask extensions
        public static bool Contains(this LayerMask mask, int layer)
        {
            return (mask.value & (1 << layer)) != 0;
        }

        // Bounds extensions
        public static bool ContainsXZ(this Bounds bounds, Vector3 point)
        {
            return point.x >= bounds.min.x && point.x <= bounds.max.x &&
                   point.z >= bounds.min.z && point.z <= bounds.max.z;
        }
    }
}
