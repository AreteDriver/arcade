using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Selection
{
    /// <summary>
    /// Component that makes an object selectable.
    /// Attach to units, buildings, etc.
    /// </summary>
    public class Selectable : MonoBehaviour
    {
        [Header("Selection Settings")]
        [SerializeField] private SelectableType selectableType = SelectableType.Unit;
        [SerializeField] private int selectionPriority = 0;
        [SerializeField] private bool canBeBoxSelected = true;

        [Header("Visuals")]
        [SerializeField] private GameObject selectionIndicator;
        [SerializeField] private float selectionRadius = 1f;

        private bool isSelected;
        private Team team;

        public SelectableType Type => selectableType;
        public int Priority => selectionPriority;
        public bool CanBeBoxSelected => canBeBoxSelected;
        public bool IsSelected => isSelected;
        public Team Team => team;
        public float SelectionRadius => selectionRadius;

        public event System.Action<Selectable> OnSelected;
        public event System.Action<Selectable> OnDeselected;

        private void Awake()
        {
            if (selectionIndicator != null)
            {
                selectionIndicator.SetActive(false);
            }
        }

        public void Initialize(Team team)
        {
            this.team = team;
        }

        public void Select()
        {
            if (isSelected) return;

            isSelected = true;

            if (selectionIndicator != null)
            {
                selectionIndicator.SetActive(true);
            }

            OnSelected?.Invoke(this);
        }

        public void Deselect()
        {
            if (!isSelected) return;

            isSelected = false;

            if (selectionIndicator != null)
            {
                selectionIndicator.SetActive(false);
            }

            OnDeselected?.Invoke(this);
        }

        public void SetSelectionColor(Color color)
        {
            if (selectionIndicator != null)
            {
                var renderer = selectionIndicator.GetComponent<Renderer>();
                if (renderer != null)
                {
                    var props = new MaterialPropertyBlock();
                    props.SetColor("_Color", color);
                    renderer.SetPropertyBlock(props);
                }
            }
        }

        public bool IsOwnedByPlayer()
        {
            return team != null && team.IsPlayerControlled;
        }

        public bool IsEnemy(Team otherTeam)
        {
            return team != null && team.IsEnemy(otherTeam);
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.green;
            Gizmos.DrawWireSphere(transform.position, selectionRadius);
        }
    }

    public enum SelectableType
    {
        Unit,
        Building,
        CapturePoint,
        Resource
    }
}
