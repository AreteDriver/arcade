namespace YokaiBlade.Core.Boss.ChochinObake
{
    /// <summary>
    /// States for Chochin-Obake, the lantern yokai.
    /// Teaching goal: hazards vs deflection.
    /// "Light shows the path; fire decides where you may walk."
    /// </summary>
    public enum ChochinObakeState
    {
        Inactive,
        Intro,
        /// <summary>
        /// Floating idle state, bobbing gently while selecting next attack.
        /// </summary>
        Float,
        /// <summary>
        /// Physical tongue attack - deflectable (white flash telegraph).
        /// </summary>
        TongueLash,
        /// <summary>
        /// Fire breath attack - undodgeable hazard (red glow telegraph).
        /// Player must reposition, cannot deflect.
        /// </summary>
        FlameBreath,
        /// <summary>
        /// Brief flicker/dim after attack - may reposition.
        /// </summary>
        Flicker,
        Staggered,
        Defeated
    }
}
