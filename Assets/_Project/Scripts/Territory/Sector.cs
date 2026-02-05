using System;
using UnityEngine;
using DustRTS.Core;

namespace DustRTS.Territory
{
    /// <summary>
    /// A map sector that can be controlled for resources and victory.
    /// </summary>
    public class Sector : MonoBehaviour
    {
        [Header("Identity")]
        [SerializeField] private string sectorName = "Sector";
        [SerializeField] private SectorType sectorType = SectorType.Standard;

        [Header("Control")]
        [SerializeField] private CapturePoint capturePoint;

        [Header("Resources")]
        [SerializeField] private int nanoPasteBonus = 10;
        [SerializeField] private int iskBonus = 15;

        [Header("Visuals")]
        [SerializeField] private MeshRenderer territoryHighlight;
        [SerializeField] private Color neutralColor = new(0.5f, 0.5f, 0.5f, 0.3f);

        private Team controllingTeam;

        public string SectorName => sectorName;
        public SectorType Type => sectorType;
        public Team ControllingTeam => controllingTeam;
        public bool IsNeutral => controllingTeam == null;
        public int NanoPasteBonus => nanoPasteBonus;
        public int ISKBonus => iskBonus;
        public CapturePoint CapturePoint => capturePoint;

        public event Action<Sector, Team, Team> OnControlChanged; // sector, newOwner, previousOwner

        private void Start()
        {
            if (capturePoint != null)
            {
                capturePoint.OnCaptured += HandleCapture;

                // Sync initial state
                controllingTeam = capturePoint.OwningTeam;
            }

            UpdateVisuals();
            TerritoryManager.Instance?.RegisterSector(this);
        }

        private void HandleCapture(Team newOwner)
        {
            Team previousOwner = controllingTeam;
            controllingTeam = newOwner;

            UpdateVisuals();
            OnControlChanged?.Invoke(this, newOwner, previousOwner);
        }

        public void SetControl(Team team)
        {
            Team previousOwner = controllingTeam;
            controllingTeam = team;

            if (capturePoint != null)
            {
                capturePoint.SetOwner(team);
            }

            UpdateVisuals();
            OnControlChanged?.Invoke(this, team, previousOwner);
        }

        private void UpdateVisuals()
        {
            if (territoryHighlight == null) return;

            Color color = controllingTeam != null ? controllingTeam.FactionColor : neutralColor;
            color.a = 0.3f;

            var props = new MaterialPropertyBlock();
            props.SetColor("_Color", color);
            territoryHighlight.SetPropertyBlock(props);
        }

        public bool IsOwnedBy(Team team)
        {
            return controllingTeam == team;
        }

        private void OnDestroy()
        {
            if (capturePoint != null)
            {
                capturePoint.OnCaptured -= HandleCapture;
            }
            TerritoryManager.Instance?.UnregisterSector(this);
        }
    }

    public enum SectorType
    {
        Standard,
        FuelDepot,
        Uplink
    }
}
