using UnityEngine;
using UnityEngine.UI;

namespace DustRTS.Selection
{
    /// <summary>
    /// UI element for the selection box visual.
    /// </summary>
    public class SelectionBox : MonoBehaviour
    {
        [SerializeField] private RectTransform boxRect;
        [SerializeField] private Image boxImage;
        [SerializeField] private Color boxColor = new(0.3f, 0.8f, 0.3f, 0.3f);
        [SerializeField] private Color borderColor = new(0.3f, 0.8f, 0.3f, 0.8f);

        private Vector2 startPosition;
        private bool isActive;

        public bool IsActive => isActive;
        public Rect SelectionRect { get; private set; }

        private void Awake()
        {
            if (boxRect == null)
            {
                boxRect = GetComponent<RectTransform>();
            }

            if (boxImage != null)
            {
                boxImage.color = boxColor;
            }

            Hide();
        }

        public void StartSelection(Vector2 screenPosition)
        {
            startPosition = screenPosition;
            isActive = true;
            gameObject.SetActive(true);
            UpdateBox(screenPosition);
        }

        public void UpdateSelection(Vector2 currentPosition)
        {
            if (!isActive) return;
            UpdateBox(currentPosition);
        }

        public void EndSelection()
        {
            isActive = false;
            Hide();
        }

        private void UpdateBox(Vector2 currentPosition)
        {
            // Calculate box corners
            float minX = Mathf.Min(startPosition.x, currentPosition.x);
            float maxX = Mathf.Max(startPosition.x, currentPosition.x);
            float minY = Mathf.Min(startPosition.y, currentPosition.y);
            float maxY = Mathf.Max(startPosition.y, currentPosition.y);

            // Update rect transform
            boxRect.anchoredPosition = new Vector2(minX, minY);
            boxRect.sizeDelta = new Vector2(maxX - minX, maxY - minY);

            // Store selection rect for querying
            SelectionRect = new Rect(minX, minY, maxX - minX, maxY - minY);
        }

        public void Hide()
        {
            gameObject.SetActive(false);
            SelectionRect = Rect.zero;
        }

        public bool ContainsScreenPoint(Vector2 screenPoint)
        {
            if (!isActive) return false;
            return SelectionRect.Contains(screenPoint);
        }

        public float GetArea()
        {
            return SelectionRect.width * SelectionRect.height;
        }

        public bool IsClick(float threshold = 100f)
        {
            return GetArea() < threshold;
        }
    }
}
