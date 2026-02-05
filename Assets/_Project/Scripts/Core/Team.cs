using UnityEngine;

namespace DustRTS.Core
{
    /// <summary>
    /// Represents a team/player in the match.
    /// Teams own units, control territory, and have resources.
    /// </summary>
    [System.Serializable]
    public class Team
    {
        [SerializeField] private int teamId;
        [SerializeField] private string teamName;
        [SerializeField] private Color teamColor = Color.blue;
        [SerializeField] private FactionType faction;
        [SerializeField] private bool isPlayerControlled;
        [SerializeField] private bool isNeutral;

        public int TeamId => teamId;
        public string TeamName => teamName;
        public Color FactionColor => teamColor;
        public FactionType Faction => faction;
        public bool IsPlayerControlled => isPlayerControlled;
        public bool IsNeutral => isNeutral;

        public Team(int id, string name, FactionType faction, Color color, bool isPlayer = false)
        {
            teamId = id;
            teamName = name;
            this.faction = faction;
            teamColor = color;
            isPlayerControlled = isPlayer;
            isNeutral = false;
        }

        public static Team CreateNeutral()
        {
            return new Team(-1, "Neutral", FactionType.Neutral, Color.gray)
            {
                isNeutral = true
            };
        }

        public bool IsEnemy(Team other)
        {
            if (other == null) return false;
            if (isNeutral || other.isNeutral) return false;
            return teamId != other.teamId;
        }

        public bool IsAlly(Team other)
        {
            if (other == null) return false;
            return teamId == other.teamId;
        }

        public override bool Equals(object obj)
        {
            if (obj is Team other)
            {
                return teamId == other.teamId;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return teamId.GetHashCode();
        }

        public static bool operator ==(Team a, Team b)
        {
            if (ReferenceEquals(a, b)) return true;
            if (a is null || b is null) return false;
            return a.teamId == b.teamId;
        }

        public static bool operator !=(Team a, Team b) => !(a == b);
    }

    public enum FactionType
    {
        Neutral,
        Amarr,
        Caldari,
        Minmatar
    }
}
