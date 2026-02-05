using System;
using UnityEngine;
using DustRTS.Core;
using DustRTS.Territory;

namespace DustRTS.Orbital
{
    /// <summary>
    /// An uplink station that enables orbital strikes when captured.
    /// </summary>
    public class UplinkStation : MonoBehaviour
    {
        [Header("Capture")]
        [SerializeField] private CapturePoint capturePoint;

        [Header("Visuals")]
        [SerializeField] private GameObject activeIndicator;
        [SerializeField] private GameObject beamEffect;
        [SerializeField] private ParticleSystem particleEffect;

        private Team owningTeam;
        private bool isActive;

        public Team OwningTeam => owningTeam;
        public bool IsActive => isActive && owningTeam != null;
        public CapturePoint CapturePoint => capturePoint;

        public event Action<UplinkStation, Team> OnCaptured;
        public event Action<UplinkStation> OnLost;

        private void Awake()
        {
            if (capturePoint == null)
            {
                capturePoint = GetComponent<CapturePoint>();
            }
        }

        private void Start()
        {
            if (capturePoint != null)
            {
                capturePoint.OnCaptured += HandleCaptured;
                owningTeam = capturePoint.OwningTeam;
            }

            UpdateVisuals();

            // Register with orbital manager
            var orbitalManager = OrbitalManager.Instance;
            if (orbitalManager != null && owningTeam != null)
            {
                orbitalManager.RegisterUplink(this, owningTeam);
            }
        }

        private void HandleCaptured(Team newOwner)
        {
            Team previousOwner = owningTeam;
            owningTeam = newOwner;

            // Unregister from previous owner
            if (previousOwner != null)
            {
                OrbitalManager.Instance?.UnregisterUplink(this, previousOwner);
                OnLost?.Invoke(this);
            }

            // Register with new owner
            if (newOwner != null)
            {
                OrbitalManager.Instance?.RegisterUplink(this, newOwner);
                isActive = true;
                OnCaptured?.Invoke(this, newOwner);
            }

            UpdateVisuals();
        }

        private void UpdateVisuals()
        {
            bool active = IsActive;

            if (activeIndicator != null)
            {
                activeIndicator.SetActive(active);
            }

            if (beamEffect != null)
            {
                beamEffect.SetActive(active);
            }

            if (particleEffect != null)
            {
                if (active && !particleEffect.isPlaying)
                {
                    particleEffect.Play();
                }
                else if (!active && particleEffect.isPlaying)
                {
                    particleEffect.Stop();
                }
            }

            // Set team color
            if (owningTeam != null)
            {
                SetTeamColor(owningTeam.FactionColor);
            }
        }

        private void SetTeamColor(Color color)
        {
            if (beamEffect != null)
            {
                var renderer = beamEffect.GetComponent<Renderer>();
                if (renderer != null)
                {
                    var props = new MaterialPropertyBlock();
                    props.SetColor("_Color", color);
                    renderer.SetPropertyBlock(props);
                }
            }

            if (particleEffect != null)
            {
                var main = particleEffect.main;
                main.startColor = color;
            }
        }

        public bool IsOwnedBy(Team team)
        {
            return owningTeam == team;
        }

        private void OnDestroy()
        {
            if (capturePoint != null)
            {
                capturePoint.OnCaptured -= HandleCaptured;
            }

            if (owningTeam != null)
            {
                OrbitalManager.Instance?.UnregisterUplink(this, owningTeam);
            }
        }
    }
}
