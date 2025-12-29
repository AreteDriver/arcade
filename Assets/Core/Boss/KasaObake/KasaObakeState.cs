namespace YokaiBlade.Core.Boss.KasaObake
{
    /// <summary>
    /// States for Kasa-Obake, the umbrella yokai.
    /// Teaching goal: timing through playfulness.
    /// "Even the foolish reveal their rhythm if you watch them long enough."
    /// </summary>
    public enum KasaObakeState
    {
        Inactive,
        Intro,
        /// <summary>
        /// Rhythmic hopping pattern. Counts 1-2-3, attacks on 3.
        /// </summary>
        Hopping,
        /// <summary>
        /// Quick tongue attack - deflectable.
        /// </summary>
        TongueLash,
        /// <summary>
        /// Area spin attack - requires distance or precise timing.
        /// Telegraphed by a wobble on hop 2.
        /// </summary>
        Spin,
        /// <summary>
        /// Brief celebration after hitting player - teaches punishment.
        /// </summary>
        Taunt,
        Staggered,
        Defeated
    }
}
