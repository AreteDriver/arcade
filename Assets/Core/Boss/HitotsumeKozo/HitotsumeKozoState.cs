namespace YokaiBlade.Core.Boss.HitotsumeKozo
{
    /// <summary>
    /// States for Hitotsume-Kozo, the one-eyed boy yokai.
    /// Teaching goal: chase and controlled aggression.
    /// "The timid are never caught, but they are never finished."
    /// </summary>
    public enum HitotsumeKozoState
    {
        Inactive,
        Intro,
        /// <summary>
        /// Running away from player. Must be chased.
        /// </summary>
        Flee,
        /// <summary>
        /// Stopped to taunt/mock player. Brief vulnerability window.
        /// </summary>
        Taunt,
        /// <summary>
        /// Cornered or caught. Will fight back.
        /// </summary>
        Cornered,
        /// <summary>
        /// Desperate attack when cornered - deflectable.
        /// </summary>
        PanicSwipe,
        /// <summary>
        /// Healing due to player passivity. Punishes timid play.
        /// </summary>
        Regenerate,
        Staggered,
        Defeated
    }
}
