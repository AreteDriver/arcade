using UnityEngine;

namespace DustRTS.Utility
{
    public static class MathUtils
    {
        /// <summary>
        /// Remap a value from one range to another.
        /// </summary>
        public static float Remap(float value, float fromMin, float fromMax, float toMin, float toMax)
        {
            float t = Mathf.InverseLerp(fromMin, fromMax, value);
            return Mathf.Lerp(toMin, toMax, t);
        }

        /// <summary>
        /// Clamp and remap a value.
        /// </summary>
        public static float RemapClamped(float value, float fromMin, float fromMax, float toMin, float toMax)
        {
            value = Mathf.Clamp(value, fromMin, fromMax);
            return Remap(value, fromMin, fromMax, toMin, toMax);
        }

        /// <summary>
        /// Get a point on a circle.
        /// </summary>
        public static Vector3 PointOnCircle(Vector3 center, float radius, float angle)
        {
            float rad = angle * Mathf.Deg2Rad;
            return center + new Vector3(
                Mathf.Cos(rad) * radius,
                0f,
                Mathf.Sin(rad) * radius
            );
        }

        /// <summary>
        /// Get points distributed evenly on a circle.
        /// </summary>
        public static Vector3[] PointsOnCircle(Vector3 center, float radius, int count, float startAngle = 0f)
        {
            var points = new Vector3[count];
            float angleStep = 360f / count;

            for (int i = 0; i < count; i++)
            {
                points[i] = PointOnCircle(center, radius, startAngle + i * angleStep);
            }

            return points;
        }

        /// <summary>
        /// Check if a point is within a cone.
        /// </summary>
        public static bool IsInCone(Vector3 origin, Vector3 direction, Vector3 point, float coneAngle, float maxDistance)
        {
            Vector3 toPoint = point - origin;
            float distance = toPoint.magnitude;

            if (distance > maxDistance) return false;

            float angle = Vector3.Angle(direction, toPoint);
            return angle <= coneAngle * 0.5f;
        }

        /// <summary>
        /// Smooth damp angle (handles wrapping).
        /// </summary>
        public static float SmoothDampAngle(float current, float target, ref float velocity, float smoothTime)
        {
            return Mathf.SmoothDampAngle(current, target, ref velocity, smoothTime);
        }

        /// <summary>
        /// Get the closest point on a line segment.
        /// </summary>
        public static Vector3 ClosestPointOnLineSegment(Vector3 point, Vector3 lineStart, Vector3 lineEnd)
        {
            Vector3 line = lineEnd - lineStart;
            float len = line.magnitude;
            line.Normalize();

            float d = Mathf.Clamp(Vector3.Dot(point - lineStart, line), 0f, len);
            return lineStart + line * d;
        }

        /// <summary>
        /// Calculate the signed angle between two vectors on the XZ plane.
        /// </summary>
        public static float SignedAngleXZ(Vector3 from, Vector3 to)
        {
            from.y = 0;
            to.y = 0;
            return Vector3.SignedAngle(from, to, Vector3.up);
        }

        /// <summary>
        /// Exponential decay for smooth interpolation.
        /// Use instead of Lerp for frame-rate independent smoothing.
        /// </summary>
        public static float ExpDecay(float current, float target, float decay, float dt)
        {
            return target + (current - target) * Mathf.Exp(-decay * dt);
        }

        public static Vector3 ExpDecay(Vector3 current, Vector3 target, float decay, float dt)
        {
            return new Vector3(
                ExpDecay(current.x, target.x, decay, dt),
                ExpDecay(current.y, target.y, decay, dt),
                ExpDecay(current.z, target.z, decay, dt)
            );
        }
    }
}
