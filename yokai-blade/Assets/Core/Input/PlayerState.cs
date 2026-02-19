namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Current state of the player character.
    /// Determines which actions are available.
    /// </summary>
    public enum PlayerState
    {
        /// <summary>
        /// Normal state. Can move, attack, deflect, dodge.
        /// </summary>
        Idle,

        /// <summary>
        /// Moving. Can transition to any action.
        /// </summary>
        Moving,

        /// <summary>
        /// In attack animation. Limited cancels.
        /// Can cancel into Deflect (always).
        /// </summary>
        Attacking,

        /// <summary>
        /// In deflect animation. Waiting for result.
        /// </summary>
        Deflecting,

        /// <summary>
        /// In dodge animation. Invincible.
        /// Cannot cancel.
        /// </summary>
        Dodging,

        /// <summary>
        /// Hit stun. Cannot act.
        /// </summary>
        Stunned,

        /// <summary>
        /// Recovery after action. Can buffer inputs.
        /// </summary>
        Recovering,

        /// <summary>
        /// Dead. No actions.
        /// </summary>
        Dead
    }

    /// <summary>
    /// Extension methods for PlayerState.
    /// </summary>
    public static class PlayerStateExtensions
    {
        /// <summary>
        /// Check if the player can perform a specific action in this state.
        /// INVARIANT: Deflect can always be performed except when dead or already deflecting.
        /// </summary>
        public static bool CanPerform(this PlayerState state, InputAction action)
        {
            // Dead = no actions
            if (state == PlayerState.Dead)
            {
                return false;
            }

            // Deflect always wins (except when dead or already deflecting)
            if (action == InputAction.Deflect)
            {
                return state != PlayerState.Deflecting;
            }

            // Other actions depend on state
            return state switch
            {
                PlayerState.Idle => true,
                PlayerState.Moving => true,
                PlayerState.Recovering => true,
                PlayerState.Attacking => false,  // Can only deflect out of attack
                PlayerState.Deflecting => false,
                PlayerState.Dodging => false,
                PlayerState.Stunned => false,
                _ => false
            };
        }

        /// <summary>
        /// Check if movement input is processed in this state.
        /// </summary>
        public static bool CanMove(this PlayerState state)
        {
            return state switch
            {
                PlayerState.Idle => true,
                PlayerState.Moving => true,
                PlayerState.Recovering => true,
                _ => false
            };
        }

        /// <summary>
        /// Check if inputs should be buffered in this state.
        /// </summary>
        public static bool ShouldBuffer(this PlayerState state)
        {
            return state switch
            {
                PlayerState.Attacking => true,
                PlayerState.Deflecting => true,
                PlayerState.Dodging => true,
                PlayerState.Recovering => true,
                PlayerState.Stunned => true,
                _ => false
            };
        }
    }
}
