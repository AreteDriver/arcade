using UnityEngine;

namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Debug overlay showing last emitted telegraph.
    /// Displays in corner of screen during development.
    ///
    /// Required by spec: "Debug overlay prints last semantic emitted"
    /// </summary>
    public class TelegraphDebugOverlay : MonoBehaviour
    {
        [SerializeField]
        [Tooltip("How long to highlight recent emissions.")]
        private float _highlightDuration = 0.5f;

        [SerializeField]
        [Tooltip("Position offset from corner.")]
        private Vector2 _offset = new Vector2(10, 10);

        [SerializeField]
        private bool _showInBuilds = false;

        private GUIStyle _boxStyle;
        private GUIStyle _labelStyle;
        private GUIStyle _valueStyle;

        private void OnGUI()
        {
            if (!Debug.isDebugBuild && !_showInBuilds)
            {
                return;
            }

            EnsureStyles();

            float width = 280;
            float height = 100;
            float x = Screen.width - width - _offset.x;
            float y = _offset.y;

            var rect = new Rect(x, y, width, height);

            // Highlight box if recent emission
            bool isRecent = Time.time - TelegraphSystem.LastEmissionTime < _highlightDuration;
            Color boxColor = isRecent ? new Color(1f, 1f, 1f, 0.9f) : new Color(0f, 0f, 0f, 0.7f);

            GUI.backgroundColor = boxColor;
            GUI.Box(rect, GUIContent.none, _boxStyle);
            GUI.backgroundColor = Color.white;

            GUILayout.BeginArea(new Rect(x + 10, y + 5, width - 20, height - 10));
            GUILayout.BeginVertical();

            // Title
            GUILayout.Label("TELEGRAPH DEBUG", _labelStyle);

            // Last semantic
            Color semanticColor = GetSemanticColor(TelegraphSystem.LastSemantic);
            string semanticName = TelegraphSystem.LastSemantic.ToString();
            if (isRecent)
            {
                semanticName = $"► {semanticName}";
            }

            var oldColor = GUI.color;
            GUI.color = semanticColor;
            GUILayout.Label(semanticName, _valueStyle);
            GUI.color = oldColor;

            // Attack ID
            string attackId = string.IsNullOrEmpty(TelegraphSystem.LastContext.AttackId)
                ? "(none)"
                : TelegraphSystem.LastContext.AttackId;
            GUILayout.Label($"Attack: {attackId}", _labelStyle);

            // Time since emission
            float timeSince = Time.time - TelegraphSystem.LastEmissionTime;
            GUILayout.Label($"Age: {timeSince:F2}s", _labelStyle);

            GUILayout.EndVertical();
            GUILayout.EndArea();
        }

        private void EnsureStyles()
        {
            if (_boxStyle != null) return;

            _boxStyle = new GUIStyle(GUI.skin.box)
            {
                normal = { background = Texture2D.whiteTexture }
            };

            _labelStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = 12,
                normal = { textColor = Color.white }
            };

            _valueStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = 16,
                fontStyle = FontStyle.Bold,
                normal = { textColor = Color.white }
            };
        }

        private Color GetSemanticColor(TelegraphSemantic semantic)
        {
            return semantic switch
            {
                TelegraphSemantic.PerfectDeflectWindow => Color.white,
                TelegraphSemantic.UndodgeableHazard => Color.red,
                TelegraphSemantic.Illusion => Color.cyan,
                TelegraphSemantic.ArenaWideThreat => new Color(1f, 0.5f, 0f), // Orange
                TelegraphSemantic.StrikeWindowOpen => Color.yellow,
                _ => Color.gray
            };
        }
    }
}
