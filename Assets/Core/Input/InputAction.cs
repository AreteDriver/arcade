namespace YokaiBlade.Core.Input
{
    /// <summary>
    /// Combat input actions available to the player.
    /// Priority order (highest to lowest): Deflect > Strike > Dodge > Move
    ///
    /// INVARIANT: Deflect always wins priority when overlapping with other inputs.
    /// </summary>
    public enum InputAction
    {
        /// <summary>
        /// No action. Used for clearing state.
        /// </summary>
        None = 0,

        /// <summary>
        /// Movement input. Lowest priority, always available.
        /// </summary>
        Move = 1,

        /// <summary>
        /// Dodge/dash action. Cancels movement, invincibility frames.
        /// </summary>
        Dodge = 2,

        /// <summary>
        /// Attack action. Commits to attack animation.
        /// </summary>
        Strike = 3,

        /// <summary>
        /// Deflect/parry action. HIGHEST PRIORITY.
        /// Always wins when overlapping with other inputs.
        /// </summary>
        Deflect = 4
    }

    /// <summary>
    /// Extension methods for InputAction priority handling.
    /// </summary>
    public static class InputActionExtensions
    {
        /// <summary>
        /// Get the priority value. Higher = more important.
        /// </summary>
        public static int Priority(this InputAction action)
        {
            return action switch
            {
                InputAction.Deflect => 100,  // Always wins
                InputAction.Strike => 50,
                InputAction.Dodge => 25,
                InputAction.Move => 10,
                _ => 0
            };
        }

        /// <summary>
        /// Check if this action is a combat action (not movement).
        /// </summary>
        public static bool IsCombatAction(this InputAction action)
        {
            return action == InputAction.Deflect ||
                   action == InputAction.Strike ||
                   action == InputAction.Dodge;
        }

        /// <summary>
        /// Check if this action can be buffered.
        /// Movement cannot be buffered.
        /// </summary>
        public static bool CanBuffer(this InputAction action)
        {
            return action.IsCombatAction();
        }
    }
}
