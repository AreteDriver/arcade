namespace YokaiBlade.Core.Boss.Oni
{
    public enum OniState
    {
        Inactive,
        Intro,
        Idle,
        // Phase 1: Heavy
        HeavyWindup,
        HeavyStrike,
        // Phase 2: Counter stance
        CounterStance,
        CounterStrike,
        // Phase 3: Barehand chains
        ComboWindup,
        ComboChain,
        Staggered,
        Defeated
    }

    public enum OniPhase
    {
        Heavy = 1,
        Counter = 2,
        Barehand = 3
    }
}
