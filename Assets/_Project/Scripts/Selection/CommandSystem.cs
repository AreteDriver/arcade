using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using DustRTS.Core;
using DustRTS.Units.Core;
using DustRTS.Territory;

namespace DustRTS.Selection
{
    /// <summary>
    /// Handles right-click commands for selected units.
    /// Move, attack, capture, etc.
    /// </summary>
    public class CommandSystem : MonoBehaviour
    {
        public static CommandSystem Instance { get; private set; }

        [Header("Configuration")]
        [SerializeField] private LayerMask groundLayer;
        [SerializeField] private LayerMask unitLayer;
        [SerializeField] private LayerMask capturePointLayer;

        [Header("Attack Move")]
        [SerializeField] private KeyCode attackMoveKey = KeyCode.A;
        [SerializeField] private Color attackMoveCursorColor = Color.red;

        [Header("Feedback")]
        [SerializeField] private GameObject moveIndicatorPrefab;
        [SerializeField] private GameObject attackIndicatorPrefab;
        [SerializeField] private AudioClip moveSound;
        [SerializeField] private AudioClip attackSound;

        private bool isAttackMoveMode;
        private SelectionManager selectionManager;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
        }

        private void Start()
        {
            ServiceLocator.Register(this);
            selectionManager = SelectionManager.Instance;
        }

        private void Update()
        {
            if (!IsInputAllowed()) return;

            HandleAttackMoveMode();
            HandleCommandInput();
        }

        private bool IsInputAllowed()
        {
            var gameManager = ServiceLocator.Get<GameManager>();
            if (gameManager == null) return true;
            return gameManager.CurrentState == GameState.Playing;
        }

        private void HandleAttackMoveMode()
        {
            // Toggle attack-move mode with 'A'
            if (Input.GetKeyDown(attackMoveKey))
            {
                isAttackMoveMode = true;
                // Change cursor here if you have cursor management
            }

            // Cancel with Escape or right-click
            if (isAttackMoveMode && (Input.GetKeyDown(KeyCode.Escape) || Input.GetMouseButtonDown(1)))
            {
                isAttackMoveMode = false;
            }
        }

        private void HandleCommandInput()
        {
            if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject())
            {
                return;
            }

            // Left-click in attack-move mode
            if (isAttackMoveMode && Input.GetMouseButtonDown(0))
            {
                IssueAttackMoveCommand();
                isAttackMoveMode = false;
                return;
            }

            // Right-click command
            if (Input.GetMouseButtonDown(1))
            {
                IssueContextCommand();
            }
        }

        private void IssueContextCommand()
        {
            if (selectionManager == null || !selectionManager.HasSelection) return;

            Ray ray = UnityEngine.Camera.main.ScreenPointToRay(Input.mousePosition);

            // Check for unit target
            if (Physics.Raycast(ray, out RaycastHit unitHit, 1000f, unitLayer))
            {
                var targetUnit = unitHit.collider.GetComponentInParent<Unit>();
                if (targetUnit != null)
                {
                    var selectedUnits = GetSelectedUnits();
                    if (selectedUnits.Count == 0) return;

                    if (targetUnit.Team.IsEnemy(selectedUnits[0].Team))
                    {
                        IssueAttackCommand(targetUnit);
                    }
                    else
                    {
                        IssueSupportCommand(targetUnit);
                    }
                    return;
                }
            }

            // Check for capture point
            if (Physics.Raycast(ray, out RaycastHit captureHit, 1000f, capturePointLayer))
            {
                var capturePoint = captureHit.collider.GetComponent<CapturePoint>();
                if (capturePoint != null)
                {
                    IssueCaptureCommand(capturePoint);
                    return;
                }
            }

            // Ground move command
            if (Physics.Raycast(ray, out RaycastHit groundHit, 1000f, groundLayer))
            {
                IssueMoveCommand(groundHit.point);
            }
        }

        private void IssueAttackMoveCommand()
        {
            Ray ray = UnityEngine.Camera.main.ScreenPointToRay(Input.mousePosition);

            if (Physics.Raycast(ray, out RaycastHit hit, 1000f, groundLayer))
            {
                var units = GetSelectedUnits();
                bool queue = Input.GetKey(KeyCode.LeftShift);

                var positions = GetFormationPositions(hit.point, units.Count);

                for (int i = 0; i < units.Count; i++)
                {
                    units[i].AttackMove(positions[i], queue);
                }

                SpawnIndicator(attackIndicatorPrefab, hit.point);
                PlaySound(attackSound);
            }
        }

        public void IssueMoveCommand(Vector3 position)
        {
            var units = GetSelectedUnits();
            if (units.Count == 0) return;

            bool queue = Input.GetKey(KeyCode.LeftShift);
            var positions = GetFormationPositions(position, units.Count);

            for (int i = 0; i < units.Count; i++)
            {
                units[i].MoveTo(positions[i], queue);
            }

            SpawnIndicator(moveIndicatorPrefab, position);
            PlaySound(moveSound);
        }

        public void IssueAttackCommand(Unit target)
        {
            var units = GetSelectedUnits();
            if (units.Count == 0) return;

            bool queue = Input.GetKey(KeyCode.LeftShift);

            foreach (var unit in units)
            {
                unit.AttackTarget(target, queue);
            }

            SpawnIndicator(attackIndicatorPrefab, target.transform.position);
            PlaySound(attackSound);
        }

        public void IssueSupportCommand(Unit target)
        {
            var units = GetSelectedUnits();
            if (units.Count == 0) return;

            bool queue = Input.GetKey(KeyCode.LeftShift);

            foreach (var unit in units)
            {
                // Follow friendly unit
                unit.Follow(target, queue);
            }
        }

        public void IssueCaptureCommand(CapturePoint capturePoint)
        {
            var units = GetSelectedUnits();
            if (units.Count == 0) return;

            bool queue = Input.GetKey(KeyCode.LeftShift);

            foreach (var unit in units)
            {
                unit.Capture(capturePoint, queue);
            }

            SpawnIndicator(moveIndicatorPrefab, capturePoint.transform.position);
        }

        public void IssueStopCommand()
        {
            var units = GetSelectedUnits();
            foreach (var unit in units)
            {
                unit.Stop();
            }
        }

        public void IssueHoldPositionCommand()
        {
            var units = GetSelectedUnits();
            foreach (var unit in units)
            {
                unit.HoldPosition();
            }
        }

        private List<Unit> GetSelectedUnits()
        {
            var result = new List<Unit>();

            if (selectionManager == null) return result;

            foreach (var selectable in selectionManager.SelectedUnits)
            {
                if (selectable != null)
                {
                    var unit = selectable.GetComponent<Unit>();
                    if (unit != null && unit.IsAlive)
                    {
                        result.Add(unit);
                    }
                }
            }

            return result;
        }

        private Vector3[] GetFormationPositions(Vector3 center, int count)
        {
            if (count <= 0) return new Vector3[0];
            if (count == 1) return new[] { center };

            var positions = new Vector3[count];

            // Simple box formation
            int cols = Mathf.CeilToInt(Mathf.Sqrt(count));
            float spacing = 2.5f;

            float offsetX = (cols - 1) * spacing * 0.5f;
            float offsetZ = ((count / cols) - 1) * spacing * 0.5f;

            for (int i = 0; i < count; i++)
            {
                int col = i % cols;
                int row = i / cols;

                positions[i] = center + new Vector3(
                    col * spacing - offsetX,
                    0f,
                    row * spacing - offsetZ
                );
            }

            return positions;
        }

        private void SpawnIndicator(GameObject prefab, Vector3 position)
        {
            if (prefab == null) return;

            var indicator = Instantiate(prefab, position + Vector3.up * 0.1f, Quaternion.identity);
            Destroy(indicator, 1f);
        }

        private void PlaySound(AudioClip clip)
        {
            if (clip == null) return;
            AudioSource.PlayClipAtPoint(clip, UnityEngine.Camera.main.transform.position, 0.5f);
        }

        private void OnDestroy()
        {
            if (Instance == this)
            {
                ServiceLocator.Unregister<CommandSystem>();
            }
        }
    }
}
