//! EVE Rebellion - Arcade Space Shooter
//!
//! A Rust/Bevy rewrite of the Python arcade game inspired by EVE Online.
//! Features 5 campaigns, EVE-style mechanics, and ship sprites from CCP's Image Server.

use bevy::prelude::*;
use bevy_egui::EguiPlugin;

mod core;
mod entities;
mod systems;
mod ui;
mod assets;
mod games;

use core::{
    GameState, GameEventsPlugin, ScoreSystem, BerserkSystem, GameProgress,
    InputConfig, AudioSettings, Difficulty, SelectedShip, CurrentStage, ShipUnlocks,
    CampaignState, MissionStartEvent, MissionCompleteEvent, WaveCompleteEvent,
    BossSpawnEvent, ActCompleteEvent,
};
use entities::EntitiesPlugin;
use systems::SystemsPlugin;
use ui::UiPlugin;
use assets::AssetsPlugin;
use games::GameModulesPlugin;

fn main() {
    App::new()
        // Bevy plugins
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: core::WINDOW_TITLE.into(),
                resolution: (core::SCREEN_WIDTH, core::SCREEN_HEIGHT).into(),
                resizable: true,
                ..default()
            }),
            ..default()
        }))
        .add_plugins(EguiPlugin)

        // Game state
        .init_state::<GameState>()

        // Resources
        .init_resource::<ScoreSystem>()
        .init_resource::<BerserkSystem>()
        .init_resource::<GameProgress>()
        .init_resource::<InputConfig>()
        .init_resource::<AudioSettings>()
        .init_resource::<Difficulty>()
        .init_resource::<SelectedShip>()
        .init_resource::<CurrentStage>()
        .init_resource::<ShipUnlocks>()
        .init_resource::<CampaignState>()

        // Campaign events
        .add_event::<MissionStartEvent>()
        .add_event::<MissionCompleteEvent>()
        .add_event::<WaveCompleteEvent>()
        .add_event::<BossSpawnEvent>()
        .add_event::<ActCompleteEvent>()

        // Game plugins
        .add_plugins((
            AssetsPlugin,
            GameEventsPlugin,
            EntitiesPlugin,
            SystemsPlugin,
            UiPlugin,
            GameModulesPlugin,
        ))

        // Setup
        .add_systems(Startup, setup)

        .run();
}

/// Initial game setup
fn setup(mut commands: Commands) {
    // Use 2D camera - sprites work reliably with this
    commands.spawn(Camera2d);

    info!("EVE Rebellion initialized!");
}
