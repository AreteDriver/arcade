using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using DustRTS.Core;
using DustRTS.Camera;

namespace DustRTS.Selection
{
    /// <summary>
    /// Manages unit selection - click, box select, control groups.
    /// </summary>
    public class SelectionManager : MonoBehaviour
    {
        public static SelectionManager Instance { get; private set; }

        [Header("Configuration")]
        [SerializeField] private LayerMask selectableLayer;
        [SerializeField] private LayerMask groundLayer;
        [SerializeField] private float clickThreshold = 100f;
        [SerializeField] private float doubleClickTime = 0.3f;

        [Header("UI")]
        [SerializeField] private SelectionBox selectionBox;

        [Header("Audio")]
        [SerializeField] private AudioClip selectSound;
        [SerializeField] private AudioClip multiSelectSound;

        // State
        private List<Selectable> selectedUnits = new();
        private List<Selectable> previewUnits = new();
        private ControlGroupManager controlGroups;
        private Vector2 boxStartPosition;
        private bool isBoxSelecting;
        private float lastClickTime;
        private Selectable lastClickedUnit;
        private Team playerTeam;

        public IReadOnlyList<Selectable> SelectedUnits => selectedUnits;
        public event Action<List<Selectable>> OnSelectionChanged;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            controlGroups = new ControlGroupManager();
        }

        private void Start()
        {
            ServiceLocator.Register(this);

            var matchManager = ServiceLocator.Get<MatchManager>();
            if (matchManager != null)
            {
                playerTeam = matchManager.PlayerTeam;
            }
        }

        private void Update()
        {
            if (!IsInputAllowed()) return;

            HandleSelectionInput();
            HandleControlGroups();
        }

        private bool IsInputAllowed()
        {
            var gameManager = ServiceLocator.Get<GameManager>();
            if (gameManager == null) return true;
            return gameManager.CurrentState == GameState.Playing;
        }

        private void HandleSelectionInput()
        {
            // Ignore if over UI
            if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject())
            {
                return;
            }

            // Start selection
            if (Input.GetMouseButtonDown(0))
            {
                boxStartPosition = Input.mousePosition;
                isBoxSelecting = true;

                if (selectionBox != null)
                {
                    selectionBox.StartSelection(boxStartPosition);
                }
            }

            // Update selection box
            if (isBoxSelecting && selectionBox != null)
            {
                selectionBox.UpdateSelection(Input.mousePosition);
                UpdatePreviewSelection();
            }

            // End selection
            if (Input.GetMouseButtonUp(0) && isBoxSelecting)
            {
                CompleteSelection();
                isBoxSelecting = false;

                if (selectionBox != null)
                {
                    selectionBox.EndSelection();
                }
            }
        }

        private void HandleControlGroups()
        {
            // Number keys 1-9 and 0
            for (int i = 0; i <= 9; i++)
            {
                KeyCode key = i == 0 ? KeyCode.Alpha0 : KeyCode.Alpha1 + (i - 1);

                if (Input.GetKeyDown(key))
                {
                    bool ctrl = Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl);
                    bool shift = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
                    bool alt = Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt);

                    if (ctrl)
                    {
                        // Assign control group
                        controlGroups.AssignGroup(i, selectedUnits, shift);
                    }
                    else if (alt)
                    {
                        // Add current selection to group
                        controlGroups.AssignGroup(i, selectedUnits, additive: true);
                    }
                    else
                    {
                        // Select control group
                        SelectControlGroup(i, shift);
                    }
                }
            }
        }

        private void UpdatePreviewSelection()
        {
            if (selectionBox == null || !selectionBox.IsActive) return;

            previewUnits.Clear();

            var allSelectables = FindObjectsByType<Selectable>(FindObjectsSortMode.None);
            var camera = UnityEngine.Camera.main;

            foreach (var selectable in allSelectables)
            {
                if (!selectable.CanBeBoxSelected) continue;
                if (!selectable.IsOwnedByPlayer()) continue;

                Vector3 screenPos = camera.WorldToScreenPoint(selectable.transform.position);

                // Check if behind camera
                if (screenPos.z < 0) continue;

                if (selectionBox.ContainsScreenPoint(screenPos))
                {
                    previewUnits.Add(selectable);
                }
            }
        }

        private void CompleteSelection()
        {
            bool isClick = selectionBox == null || selectionBox.IsClick(clickThreshold);
            bool additive = Input.GetKey(KeyCode.LeftShift);
            bool toggle = Input.GetKey(KeyCode.LeftControl);

            if (isClick)
            {
                // Single click selection
                Selectable clicked = GetSelectableUnderMouse();

                if (clicked != null)
                {
                    // Double-click detection
                    bool isDoubleClick = (Time.time - lastClickTime < doubleClickTime) &&
                                          clicked == lastClickedUnit;
                    lastClickTime = Time.time;
                    lastClickedUnit = clicked;

                    if (isDoubleClick)
                    {
                        SelectAllOfTypeOnScreen(clicked);
                    }
                    else if (toggle)
                    {
                        ToggleSelection(clicked);
                    }
                    else if (additive)
                    {
                        AddToSelection(clicked);
                    }
                    else
                    {
                        SelectSingle(clicked);
                    }
                }
                else if (!additive && !toggle)
                {
                    ClearSelection();
                }
            }
            else
            {
                // Box selection
                if (!additive && !toggle)
                {
                    ClearSelection();
                }

                foreach (var unit in previewUnits)
                {
                    if (toggle)
                    {
                        ToggleSelection(unit);
                    }
                    else
                    {
                        AddToSelection(unit);
                    }
                }
            }

            previewUnits.Clear();
            OnSelectionChanged?.Invoke(new List<Selectable>(selectedUnits));
        }

        private Selectable GetSelectableUnderMouse()
        {
            Ray ray = UnityEngine.Camera.main.ScreenPointToRay(Input.mousePosition);

            if (Physics.Raycast(ray, out RaycastHit hit, 1000f, selectableLayer))
            {
                return hit.collider.GetComponentInParent<Selectable>();
            }

            return null;
        }

        public void SelectSingle(Selectable selectable)
        {
            if (selectable == null) return;

            ClearSelection();
            AddToSelection(selectable);
        }

        public void AddToSelection(Selectable selectable)
        {
            if (selectable == null) return;
            if (selectedUnits.Contains(selectable)) return;

            // Only select player-owned units
            if (!selectable.IsOwnedByPlayer()) return;

            selectedUnits.Add(selectable);
            selectable.Select();

            // Sort by priority
            selectedUnits = selectedUnits.OrderByDescending(s => s.Priority).ToList();
        }

        public void RemoveFromSelection(Selectable selectable)
        {
            if (selectable == null) return;
            if (!selectedUnits.Contains(selectable)) return;

            selectedUnits.Remove(selectable);
            selectable.Deselect();
        }

        public void ToggleSelection(Selectable selectable)
        {
            if (selectable == null) return;

            if (selectedUnits.Contains(selectable))
            {
                RemoveFromSelection(selectable);
            }
            else
            {
                AddToSelection(selectable);
            }
        }

        public void ClearSelection()
        {
            foreach (var unit in selectedUnits)
            {
                if (unit != null)
                {
                    unit.Deselect();
                }
            }
            selectedUnits.Clear();
        }

        public void SelectControlGroup(int number, bool additive = false)
        {
            var group = controlGroups.GetGroup(number);
            if (group == null || group.IsEmpty) return;

            if (!additive)
            {
                ClearSelection();
            }

            foreach (var member in group.GetAliveMembers())
            {
                AddToSelection(member);
            }

            // Double-tap to center camera on group
            if (!additive)
            {
                var camera = RTSCamera.Instance;
                if (camera != null)
                {
                    camera.JumpToPosition(group.GetCenterPosition());
                }
            }

            OnSelectionChanged?.Invoke(new List<Selectable>(selectedUnits));
        }

        public void SelectAllOfTypeOnScreen(Selectable reference)
        {
            if (reference == null) return;

            var camera = UnityEngine.Camera.main;
            var allSelectables = FindObjectsByType<Selectable>(FindObjectsSortMode.None);

            ClearSelection();

            foreach (var selectable in allSelectables)
            {
                if (!selectable.IsOwnedByPlayer()) continue;
                if (selectable.Type != reference.Type) continue;

                // Check if on screen
                Vector3 screenPos = camera.WorldToScreenPoint(selectable.transform.position);
                if (screenPos.z < 0) continue;
                if (screenPos.x < 0 || screenPos.x > Screen.width) continue;
                if (screenPos.y < 0 || screenPos.y > Screen.height) continue;

                AddToSelection(selectable);
            }

            OnSelectionChanged?.Invoke(new List<Selectable>(selectedUnits));
        }

        public void SelectAll()
        {
            var allSelectables = FindObjectsByType<Selectable>(FindObjectsSortMode.None);

            ClearSelection();

            foreach (var selectable in allSelectables)
            {
                if (selectable.IsOwnedByPlayer())
                {
                    AddToSelection(selectable);
                }
            }

            OnSelectionChanged?.Invoke(new List<Selectable>(selectedUnits));
        }

        public List<T> GetSelectedOfType<T>() where T : Component
        {
            var result = new List<T>();
            foreach (var unit in selectedUnits)
            {
                if (unit != null)
                {
                    var component = unit.GetComponent<T>();
                    if (component != null)
                    {
                        result.Add(component);
                    }
                }
            }
            return result;
        }

        public bool HasSelection => selectedUnits.Count > 0;

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<SelectionManager>();
            }
        }
    }
}
