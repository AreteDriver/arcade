//! Triglavian Invasion Campaign
//!
//! 9-mission campaign across contested systems.

use super::ships::*;
use crate::core::GameState;
use bevy::prelude::*;

/// Campaign state resource
#[derive(Resource, Default)]
pub struct TriglavianCampaignState {
    pub current_mission: u32,
    pub current_wave: u32,
    pub waves_in_mission: u32,
    pub enemies_remaining: u32,
    pub mission_complete: bool,
    pub boss_spawned: bool,
}

impl TriglavianCampaignState {
    pub fn reset(&mut self) {
        self.current_mission = 0;
        self.current_wave = 0;
        self.waves_in_mission = 0;
        self.enemies_remaining = 0;
        self.mission_complete = false;
        self.boss_spawned = false;
    }

    pub fn start_mission(&mut self, mission: u32) {
        self.current_mission = mission;
        self.current_wave = 0;
        self.enemies_remaining = 0;
        self.mission_complete = false;
        self.boss_spawned = false;

        // Waves per mission (increases with difficulty)
        self.waves_in_mission = match mission {
            0..=2 => 3,
            3..=5 => 4,
            _ => 5,
        };
    }
}

// =============================================================================
// MISSION DEFINITIONS
// =============================================================================

/// Mission information
#[derive(Clone, Debug)]
pub struct MissionInfo {
    pub name: &'static str,
    pub system: &'static str,
    pub description: &'static str,
    pub boss_type_id: u32,
    pub boss_name: &'static str,
}

/// Get mission info for EDENCOM campaign
pub fn edencom_missions() -> Vec<MissionInfo> {
    vec![
        MissionInfo {
            name: "First Contact",
            system: "Niarja",
            description: "Triglavian scouts have been spotted. Intercept and eliminate.",
            boss_type_id: triglavian::VEDMAK,
            boss_name: "Raznaborg Vedmak",
        },
        MissionInfo {
            name: "Stellar Transmuter",
            system: "Raravoss",
            description: "Prevent the Triglavians from deploying their stellar harvester.",
            boss_type_id: triglavian::DREKAVAC,
            boss_name: "Perun Drekavac",
        },
        MissionInfo {
            name: "Liminality Rising",
            system: "Sakenta",
            description: "The system is approaching Final Liminality. Hold the line.",
            boss_type_id: triglavian::LESHAK,
            boss_name: "Veles Leshak",
        },
        MissionInfo {
            name: "Pochven's Edge",
            system: "Vale",
            description: "Systems are falling to Pochven. We must not lose Vale.",
            boss_type_id: triglavian::IKITURSA,
            boss_name: "Svarog Ikitursa",
        },
        MissionInfo {
            name: "Proving Ground",
            system: "Kuharah",
            description: "The Collective seeks to prove their might. Show them ours.",
            boss_type_id: triglavian::DREKAVAC,
            boss_name: "Proving Drekavac",
        },
        MissionInfo {
            name: "Gate Defense",
            system: "Otela",
            description: "Defend the stargate from Triglavian assault.",
            boss_type_id: triglavian::LESHAK,
            boss_name: "Siege Leshak",
        },
        MissionInfo {
            name: "World Ark Assault",
            system: "Kino",
            description: "A World Ark has been detected. This is our chance.",
            boss_type_id: triglavian::XORDAZH,
            boss_name: "Xordazh World Ark",
        },
        MissionInfo {
            name: "Zorya's Domain",
            system: "Pochven Gate",
            description: "Push into Pochven and strike at the heart of the invasion.",
            boss_type_id: triglavian::LESHAK,
            boss_name: "Zorya's Champion",
        },
        MissionInfo {
            name: "The Final Proving",
            system: "Triglavian Stronghold",
            description: "End the invasion. Victory or death.",
            boss_type_id: triglavian::XORDAZH,
            boss_name: "Zorya Triglav",
        },
    ]
}

/// Get mission info for Triglavian campaign
pub fn triglavian_missions() -> Vec<MissionInfo> {
    vec![
        MissionInfo {
            name: "Glory to the Collective",
            system: "Niarja",
            description: "Prove yourself worthy by destroying EDENCOM scouts.",
            boss_type_id: edencom::SKYBREAKER,
            boss_name: "EDENCOM Vanguard",
        },
        MissionInfo {
            name: "Stellar Manipulation",
            system: "Raravoss",
            description: "Protect the Stellar Transmuter from EDENCOM interference.",
            boss_type_id: edencom::THUNDERCHILD,
            boss_name: "EDENCOM Commander",
        },
        MissionInfo {
            name: "Embrace Liminality",
            system: "Sakenta",
            description: "Push the system toward Final Liminality.",
            boss_type_id: edencom::STORMBRINGER,
            boss_name: "EDENCOM Battlegroup",
        },
        MissionInfo {
            name: "Claim for Pochven",
            system: "Vale",
            description: "Vale will join Pochven. Eliminate all resistance.",
            boss_type_id: edencom::THUNDERCHILD,
            boss_name: "Imperial Thunderchild",
        },
        MissionInfo {
            name: "The Flow of Vyraj",
            system: "Kuharah",
            description: "Demonstrate superiority in the Proving.",
            boss_type_id: edencom::STORMBRINGER,
            boss_name: "CONCORD Stormbringer",
        },
        MissionInfo {
            name: "Gate Seizure",
            system: "Otela",
            description: "Capture the stargate for Collective use.",
            boss_type_id: edencom::APOCALYPSE,
            boss_name: "Amarr Dreadnought",
        },
        MissionInfo {
            name: "Empire's Fall",
            system: "Kino",
            description: "Break the empire fleet defending this system.",
            boss_type_id: edencom::RAVEN,
            boss_name: "Caldari Fleet Commander",
        },
        MissionInfo {
            name: "Weaving Pochven",
            system: "New Eden Core",
            description: "The wormhole network must grow. Destroy all obstacles.",
            boss_type_id: edencom::MEGATHRON,
            boss_name: "Gallente Titan Escort",
        },
        MissionInfo {
            name: "Totality",
            system: "Jita",
            description: "All of New Eden shall join Pochven.",
            boss_type_id: edencom::STORMBRINGER,
            boss_name: "EDENCOM Supreme Commander",
        },
    ]
}

// =============================================================================
// CAMPAIGN SYSTEMS
// =============================================================================

/// Start a Triglavian campaign mission
pub fn start_trig_mission(
    mut state: ResMut<TriglavianCampaignState>,
    active: Res<crate::games::ActiveModule>,
) {
    let mission = state.current_mission;
    state.start_mission(mission);

    let faction = active.player_faction.as_deref().unwrap_or("edencom");
    let missions = if faction == "edencom" {
        edencom_missions()
    } else {
        triglavian_missions()
    };

    if let Some(info) = missions.get(mission as usize) {
        info!("Starting mission {}: {} - {}", mission + 1, info.name, info.system);
    }
}

/// Update mission state
pub fn update_trig_mission(
    mut state: ResMut<TriglavianCampaignState>,
    mut next_state: ResMut<NextState<GameState>>,
) {
    // Check for mission complete (all waves done)
    if state.current_wave >= state.waves_in_mission
        && state.enemies_remaining == 0
        && !state.boss_spawned
    {
        // Transition to boss fight
        state.boss_spawned = true;
        next_state.set(GameState::BossIntro);
    }
}

/// Check if current wave is complete
pub fn check_trig_wave_complete(
    mut state: ResMut<TriglavianCampaignState>,
    enemies: Query<Entity, With<crate::entities::Enemy>>,
) {
    state.enemies_remaining = enemies.iter().count() as u32;
}

/// Spawn next wave of enemies
pub fn spawn_trig_wave(
    _commands: Commands,
    mut state: ResMut<TriglavianCampaignState>,
    active: Res<crate::games::ActiveModule>,
    _asset_server: Res<AssetServer>,
    _enemies: Query<Entity, With<crate::entities::Enemy>>,
) {
    // Only spawn if no enemies and wave not complete
    if state.enemies_remaining > 0 || state.current_wave >= state.waves_in_mission {
        return;
    }

    let faction = active.player_faction.as_deref().unwrap_or("edencom");
    let _spawn_weights = if faction == "edencom" {
        triglavian_spawn_weights()
    } else {
        edencom_spawn_weights()
    };

    // Calculate enemies for this wave
    let base_count = 5 + state.current_mission * 2;
    let wave_bonus = state.current_wave * 2;
    let enemy_count = base_count + wave_bonus;

    info!(
        "Spawning wave {}/{} with {} enemies",
        state.current_wave + 1,
        state.waves_in_mission,
        enemy_count
    );

    // Spawn enemies (simplified - full implementation would use proper spawn system)
    // This is a placeholder - actual spawning would integrate with the enemy spawn system

    state.current_wave += 1;
    state.enemies_remaining = enemy_count;
}

// =============================================================================
// BOSS SYSTEMS
// =============================================================================

/// Spawn mission boss
pub fn spawn_trig_boss(
    _commands: Commands,
    state: Res<TriglavianCampaignState>,
    active: Res<crate::games::ActiveModule>,
) {
    let faction = active.player_faction.as_deref().unwrap_or("edencom");
    let missions = if faction == "edencom" {
        edencom_missions()
    } else {
        triglavian_missions()
    };

    if let Some(info) = missions.get(state.current_mission as usize) {
        info!("Spawning boss: {} ({})", info.boss_name, info.boss_type_id);
        // Boss spawn would integrate with existing boss system
    }
}

/// Update boss behavior
pub fn update_trig_boss() {
    // Boss AI updates - placeholder for actual implementation
}

/// Check if boss is defeated
pub fn check_trig_boss_defeated(
    mut state: ResMut<TriglavianCampaignState>,
    mut next_state: ResMut<NextState<GameState>>,
    bosses: Query<Entity, With<crate::entities::boss::Boss>>,
) {
    if bosses.is_empty() && state.boss_spawned {
        state.mission_complete = true;
        state.current_mission += 1;

        // Check for campaign complete
        let total_missions = 9;
        if state.current_mission >= total_missions {
            next_state.set(GameState::Victory);
        } else {
            next_state.set(GameState::StageComplete);
        }
    }
}
