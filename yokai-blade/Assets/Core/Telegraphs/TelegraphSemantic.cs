namespace YokaiBlade.Core.Telegraphs
{
    /// <summary>
    /// Global telegraph semantics. Each value has exactly ONE meaning across the entire game.
    /// Bosses cannot override or reinterpret these meanings.
    ///
    /// INVARIANT: One semantic = one meaning, always.
    /// </summary>
    public enum TelegraphSemantic
    {
        /// <summary>
        /// No telegraph. Used for clearing state.
        /// </summary>
        None = 0,

        /// <summary>
        /// White flash (1 frame). Perfect deflect window is NOW.
        /// Player response: Press deflect immediately.
        /// </summary>
        PerfectDeflectWindow = 1,

        /// <summary>
        /// Red glow. Undodgeable hazard - cannot be deflected.
        /// Player response: Reposition immediately.
        /// </summary>
        UndodgeableHazard = 2,

        /// <summary>
        /// Blue shimmer. Illusion that never damages.
        /// Player response: Safe to ignore, focus on real threats.
        /// </summary>
        Illusion = 3,

        /// <summary>
        /// Low bass audio cue. Arena-wide threat incoming.
        /// Player response: Prepare for major attack or repositioning.
        /// </summary>
        ArenaWideThreat = 4,

        /// <summary>
        /// High chime audio cue. Strike window is opening.
        /// Player response: Attack now.
        /// </summary>
        StrikeWindowOpen = 5
    }
}
