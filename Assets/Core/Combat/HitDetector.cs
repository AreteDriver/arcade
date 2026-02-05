using System;
using UnityEngine;

namespace YokaiBlade.Core.Combat
{
    public class HitDetector : MonoBehaviour
    {
        [SerializeField] private LayerMask _targetLayers;
        [SerializeField] private bool _debugDraw;

        public event Action<AttackDefinition, Collider> OnHit;

        private AttackRunner _runner;
        private readonly Collider[] _hitBuffer = new Collider[8];

        private void Awake()
        {
            _runner = GetComponent<AttackRunner>();
            if (_runner != null)
            {
                _runner.OnHitFrameActive += CheckHits;
            }
        }

        private void OnDestroy()
        {
            if (_runner != null)
            {
                _runner.OnHitFrameActive -= CheckHits;
            }
        }

        private void CheckHits(AttackDefinition attack)
        {
            Vector3 center = transform.TransformPoint(attack.HitboxOffset);
            Vector3 halfExtents = attack.HitboxSize * 0.5f;

            int count = Physics.OverlapBoxNonAlloc(center, halfExtents, _hitBuffer, transform.rotation, _targetLayers);

            for (int i = 0; i < count; i++)
            {
                OnHit?.Invoke(attack, _hitBuffer[i]);
            }
        }

        private void OnDrawGizmosSelected()
        {
            if (!_debugDraw || _runner == null || _runner.Current == null) return;

            var attack = _runner.Current;
            Gizmos.color = _runner.Phase == AttackPhase.Active ? Color.red : Color.yellow;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.DrawWireCube(attack.HitboxOffset, attack.HitboxSize);
        }
    }
}
