using UnityEngine;
using UnityEngine.UI;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Core.UI
{
    public class DeathPanel : MonoBehaviour
    {
        [SerializeField] private Text _attackNameText;
        [SerializeField] private Image _responseIcon;
        [SerializeField] private GameObject _panel;

        [Header("Response Icons")]
        [SerializeField] private Sprite _deflectIcon;
        [SerializeField] private Sprite _dodgeIcon;
        [SerializeField] private Sprite _jumpIcon;
        [SerializeField] private Sprite _repositionIcon;

        private DeathFeedbackSystem _feedbackSystem;

        private void Awake()
        {
            _feedbackSystem = FindObjectOfType<DeathFeedbackSystem>();
            if (_feedbackSystem != null)
            {
                _feedbackSystem.OnDeathTriggered += Show;
                _feedbackSystem.OnReadyToRetry += Hide;
            }
            Hide();
        }

        private void OnDestroy()
        {
            if (_feedbackSystem != null)
            {
                _feedbackSystem.OnDeathTriggered -= Show;
                _feedbackSystem.OnReadyToRetry -= Hide;
            }
        }

        private void Show(DeathFeedbackData data)
        {
            if (_panel != null) _panel.SetActive(true);
            if (_attackNameText != null) _attackNameText.text = data.AttackName;
            if (_responseIcon != null) _responseIcon.sprite = GetIcon(data.CorrectResponse);
        }

        private void Hide()
        {
            if (_panel != null) _panel.SetActive(false);
        }

        private Sprite GetIcon(AttackResponse response)
        {
            return response switch
            {
                AttackResponse.Deflect => _deflectIcon,
                AttackResponse.Dodge => _dodgeIcon,
                AttackResponse.Jump => _jumpIcon,
                AttackResponse.Reposition => _repositionIcon,
                _ => null
            };
        }
    }
}
