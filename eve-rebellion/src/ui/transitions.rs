//! Screen Transitions
//!
//! Smooth fade effects between game states.

#![allow(dead_code)]

use bevy::prelude::*;

use crate::core::GameState;

/// Transition plugin
pub struct TransitionPlugin;

impl Plugin for TransitionPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<TransitionState>()
            .add_event::<TransitionEvent>()
            .add_systems(Startup, setup_transition_overlay)
            .add_systems(
                Update,
                (handle_transition_events, update_transition).chain(),
            );
    }
}

/// Transition overlay marker
#[derive(Component)]
struct TransitionOverlay;

/// Current transition state
#[derive(Resource, Default)]
pub struct TransitionState {
    /// Is a transition in progress?
    pub active: bool,
    /// Current phase (FadeOut or FadeIn)
    pub phase: TransitionPhase,
    /// Progress (0.0 to 1.0)
    pub progress: f32,
    /// Fade duration in seconds
    pub duration: f32,
    /// Target state after fade out
    pub target_state: Option<GameState>,
}

/// Transition phases
#[derive(Default, Clone, Copy, PartialEq, Eq, Debug)]
pub enum TransitionPhase {
    #[default]
    Idle,
    FadeOut,
    FadeIn,
}

/// Event to trigger a transition
#[derive(Event)]
pub struct TransitionEvent {
    /// Target game state
    pub target: GameState,
    /// Fade out duration
    pub fade_out: f32,
    /// Fade in duration
    pub fade_in: f32,
}

impl TransitionEvent {
    /// Create a transition with default timing
    pub fn to(target: GameState) -> Self {
        Self {
            target,
            fade_out: 0.3,
            fade_in: 0.3,
        }
    }

    /// Create a quick transition
    pub fn quick(target: GameState) -> Self {
        Self {
            target,
            fade_out: 0.15,
            fade_in: 0.15,
        }
    }

    /// Create a slow dramatic transition
    pub fn slow(target: GameState) -> Self {
        Self {
            target,
            fade_out: 0.5,
            fade_in: 0.5,
        }
    }
}

/// Setup the transition overlay (full screen black rectangle)
fn setup_transition_overlay(mut commands: Commands) {
    commands.spawn((
        TransitionOverlay,
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(0.0),
            top: Val::Px(0.0),
            width: Val::Percent(100.0),
            height: Val::Percent(100.0),
            ..default()
        },
        BackgroundColor(Color::srgba(0.0, 0.0, 0.0, 0.0)),
        ZIndex(1000), // Above everything
    ));
}

/// Handle incoming transition events
fn handle_transition_events(
    mut events: EventReader<TransitionEvent>,
    mut state: ResMut<TransitionState>,
) {
    for event in events.read() {
        if !state.active {
            state.active = true;
            state.phase = TransitionPhase::FadeOut;
            state.progress = 0.0;
            state.duration = event.fade_out;
            state.target_state = Some(event.target);
        }
    }
}

/// Update transition progress and overlay alpha
fn update_transition(
    time: Res<Time>,
    mut state: ResMut<TransitionState>,
    mut next_game_state: ResMut<NextState<GameState>>,
    mut overlay_query: Query<&mut BackgroundColor, With<TransitionOverlay>>,
    _current_state: Res<State<GameState>>,
) {
    if !state.active {
        return;
    }

    let dt = time.delta_secs();
    state.progress += dt / state.duration;

    // Get overlay
    let Ok(mut bg) = overlay_query.get_single_mut() else {
        return;
    };

    match state.phase {
        TransitionPhase::FadeOut => {
            // Fade to black
            let alpha = state.progress.min(1.0);
            bg.0 = Color::srgba(0.0, 0.0, 0.0, alpha);

            if state.progress >= 1.0 {
                // Switch state and start fade in
                if let Some(target) = state.target_state {
                    next_game_state.set(target);
                }
                state.phase = TransitionPhase::FadeIn;
                state.progress = 0.0;
                state.duration = 0.3; // Default fade in
            }
        }
        TransitionPhase::FadeIn => {
            // Fade from black
            let alpha = 1.0 - state.progress.min(1.0);
            bg.0 = Color::srgba(0.0, 0.0, 0.0, alpha);

            if state.progress >= 1.0 {
                // Transition complete
                state.active = false;
                state.phase = TransitionPhase::Idle;
                bg.0 = Color::srgba(0.0, 0.0, 0.0, 0.0);
            }
        }
        TransitionPhase::Idle => {}
    }
}

/// Helper to check if a transition is active
pub fn transition_active(state: &TransitionState) -> bool {
    state.active
}
