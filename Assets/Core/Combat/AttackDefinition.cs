using UnityEngine;
using YokaiBlade.Core.Telegraphs;

namespace YokaiBlade.Core.Combat
{
    [CreateAssetMenu(fileName = "Attack", menuName = "YokaiBlade/Attack Definition")]
    public class AttackDefinition : ScriptableObject
    {
        private const float FRAME_DURATION = 1f / 60f;

        [Header("Identity")]
        public string AttackId;
        [TextArea(1, 2)]
        public string DisplayName;

        [Header("Timing (frames @ 60fps)")]
        [Min(1)] public int StartupFrames = 10;
        [Min(1)] public int ActiveFrames = 5;
        [Min(0)] public int RecoveryFrames = 15;

        [Header("Telegraph")]
        public TelegraphSemantic Telegraph = TelegraphSemantic.PerfectDeflectWindow;
        [Tooltip("Frames before active that telegraph emits")]
        [Min(0)] public int TelegraphLeadFrames = 5;

        [Header("Damage")]
        [Min(0)] public int Damage = 1;
        public bool Unblockable;

        [Header("Response")]
        public AttackResponse CorrectResponse = AttackResponse.Deflect;

        [Header("Hit Detection")]
        public Vector3 HitboxOffset;
        public Vector3 HitboxSize = Vector3.one;

        // Computed
        public float StartupDuration => StartupFrames * FRAME_DURATION;
        public float ActiveDuration => ActiveFrames * FRAME_DURATION;
        public float RecoveryDuration => RecoveryFrames * FRAME_DURATION;
        public float TotalDuration => (StartupFrames + ActiveFrames + RecoveryFrames) * FRAME_DURATION;
        public float TelegraphTime => (StartupFrames - TelegraphLeadFrames) * FRAME_DURATION;

        public bool Validate(out string error)
        {
            if (string.IsNullOrEmpty(AttackId))
            {
                error = "AttackId is empty";
                return false;
            }
            if (StartupFrames < 1)
            {
                error = "StartupFrames must be >= 1";
                return false;
            }
            if (ActiveFrames < 1)
            {
                error = "ActiveFrames must be >= 1";
                return false;
            }
            if (TelegraphLeadFrames > StartupFrames)
            {
                error = "TelegraphLeadFrames cannot exceed StartupFrames";
                return false;
            }
            if (Unblockable && CorrectResponse == AttackResponse.Deflect)
            {
                error = "Unblockable attack cannot have Deflect as correct response";
                return false;
            }
            if (HitboxSize.x <= 0 || HitboxSize.y <= 0 || HitboxSize.z <= 0)
            {
                error = "HitboxSize must be positive";
                return false;
            }
            error = null;
            return true;
        }

        private void OnValidate()
        {
            if (string.IsNullOrEmpty(AttackId))
                AttackId = name;
            if (!Validate(out var error))
                Debug.LogWarning($"[AttackDefinition:{name}] {error}");
        }

        private void OnEnable()
        {
            if (!Validate(out var error))
                Debug.LogError($"[AttackDefinition:{name}] {error}");
        }
    }
}
