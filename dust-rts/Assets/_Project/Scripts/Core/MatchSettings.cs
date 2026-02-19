using UnityEngine;

namespace DustRTS.Core
{
    /// <summary>
    /// Configuration for a skirmish match.
    /// Set before match starts, immutable during match.
    /// </summary>
    [CreateAssetMenu(fileName = "MatchSettings", menuName = "RTS/Match Settings")]
    public class MatchSettings : ScriptableObject
    {
        [Header("Victory Conditions")]
        [SerializeField] private int startingVictoryPoints = 500;
        [SerializeField] private int sectorsToControlForDrain = 3;
        [SerializeField] private int totalSectors = 5;
        [SerializeField] private float vpDrainPerSecond = 1f;
        [SerializeField] private float vpDrainFullControl = 3f;

        [Header("Starting Resources")]
        [SerializeField] private int startingNanoPaste = 500;
        [SerializeField] private int startingISK = 300;

        [Header("Base Income (per minute)")]
        [SerializeField] private int baseNanoPasteIncome = 50;
        [SerializeField] private int baseISKIncome = 20;

        [Header("Resource Caps")]
        [SerializeField] private int maxNanoPaste = 1000;
        [SerializeField] private int maxISK = 2000;

        [Header("Production")]
        [SerializeField] private int maxProductionQueueSize = 5;

        [Header("Time Limits")]
        [SerializeField] private float matchTimeLimitMinutes = 30f;
        [SerializeField] private bool enableTimeLimit = false;

        // Victory
        public int StartingVictoryPoints => startingVictoryPoints;
        public int SectorsToControlForDrain => sectorsToControlForDrain;
        public int TotalSectors => totalSectors;
        public float VPDrainPerSecond => vpDrainPerSecond;
        public float VPDrainFullControl => vpDrainFullControl;

        // Resources
        public int StartingNanoPaste => startingNanoPaste;
        public int StartingISK => startingISK;
        public int BaseNanoPasteIncome => baseNanoPasteIncome;
        public int BaseISKIncome => baseISKIncome;
        public int MaxNanoPaste => maxNanoPaste;
        public int MaxISK => maxISK;

        // Production
        public int MaxProductionQueueSize => maxProductionQueueSize;

        // Time
        public float MatchTimeLimitMinutes => matchTimeLimitMinutes;
        public bool EnableTimeLimit => enableTimeLimit;

        public static MatchSettings CreateDefault()
        {
            var settings = CreateInstance<MatchSettings>();
            return settings;
        }
    }
}
