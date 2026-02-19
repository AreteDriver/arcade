using UnityEngine;

namespace DustRTS.Units.Infantry
{
    /// <summary>
    /// Calculates formation positions for squad members.
    /// </summary>
    public class SquadFormation : MonoBehaviour
    {
        [Header("Formation")]
        [SerializeField] private FormationType formationType = FormationType.Line;
        [SerializeField] private float spacing = 1.5f;
        [SerializeField] private float rowSpacing = 2f;

        public FormationType Type => formationType;

        public Vector3[] GetPositions(Vector3 center, Vector3 forward, int count)
        {
            if (count <= 0) return new Vector3[0];

            return formationType switch
            {
                FormationType.Line => GetLineFormation(center, forward, count),
                FormationType.Column => GetColumnFormation(center, forward, count),
                FormationType.Wedge => GetWedgeFormation(center, forward, count),
                FormationType.Box => GetBoxFormation(center, forward, count),
                FormationType.Staggered => GetStaggeredFormation(center, forward, count),
                _ => GetLineFormation(center, forward, count)
            };
        }

        private Vector3[] GetLineFormation(Vector3 center, Vector3 forward, int count)
        {
            var positions = new Vector3[count];
            Vector3 right = Vector3.Cross(Vector3.up, forward).normalized;

            float totalWidth = (count - 1) * spacing;
            Vector3 start = center - right * (totalWidth / 2f);

            for (int i = 0; i < count; i++)
            {
                positions[i] = start + right * (i * spacing);
            }

            return positions;
        }

        private Vector3[] GetColumnFormation(Vector3 center, Vector3 forward, int count)
        {
            var positions = new Vector3[count];

            float totalDepth = (count - 1) * rowSpacing;
            Vector3 start = center + forward * (totalDepth / 2f);

            for (int i = 0; i < count; i++)
            {
                positions[i] = start - forward * (i * rowSpacing);
            }

            return positions;
        }

        private Vector3[] GetWedgeFormation(Vector3 center, Vector3 forward, int count)
        {
            var positions = new Vector3[count];
            Vector3 right = Vector3.Cross(Vector3.up, forward).normalized;

            // Leader at front
            positions[0] = center;

            // Others in V behind
            for (int i = 1; i < count; i++)
            {
                int row = (i + 1) / 2;
                int side = (i % 2 == 1) ? 1 : -1;

                Vector3 offset = -forward * (row * rowSpacing) + right * (side * row * spacing);
                positions[i] = center + offset;
            }

            return positions;
        }

        private Vector3[] GetBoxFormation(Vector3 center, Vector3 forward, int count)
        {
            var positions = new Vector3[count];
            Vector3 right = Vector3.Cross(Vector3.up, forward).normalized;

            int cols = Mathf.CeilToInt(Mathf.Sqrt(count));
            int rows = Mathf.CeilToInt((float)count / cols);

            float totalWidth = (cols - 1) * spacing;
            float totalDepth = (rows - 1) * rowSpacing;

            Vector3 start = center - right * (totalWidth / 2f) + forward * (totalDepth / 2f);

            for (int i = 0; i < count; i++)
            {
                int col = i % cols;
                int row = i / cols;

                positions[i] = start + right * (col * spacing) - forward * (row * rowSpacing);
            }

            return positions;
        }

        private Vector3[] GetStaggeredFormation(Vector3 center, Vector3 forward, int count)
        {
            var positions = new Vector3[count];
            Vector3 right = Vector3.Cross(Vector3.up, forward).normalized;

            int cols = 2;
            float staggerOffset = spacing * 0.5f;

            float totalWidth = spacing;
            float totalDepth = ((count - 1) / cols) * rowSpacing;

            Vector3 start = center - right * (totalWidth / 2f) + forward * (totalDepth / 2f);

            for (int i = 0; i < count; i++)
            {
                int col = i % cols;
                int row = i / cols;

                float xOffset = col * spacing;
                if (row % 2 == 1)
                {
                    xOffset += staggerOffset;
                }

                positions[i] = start + right * xOffset - forward * (row * rowSpacing);
            }

            return positions;
        }

        public void SetFormationType(FormationType type)
        {
            formationType = type;
        }

        public void SetSpacing(float newSpacing)
        {
            spacing = newSpacing;
        }
    }

    public enum FormationType
    {
        Line,      // Side by side
        Column,    // Single file
        Wedge,     // V shape
        Box,       // Square
        Staggered  // Offset rows
    }
}
