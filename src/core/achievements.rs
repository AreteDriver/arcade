//! Achievement System
//!
//! Tracks player achievements and unlocks.

use bevy::prelude::*;
use serde::{Deserialize, Serialize};

/// Achievement plugin
pub struct AchievementPlugin;

impl Plugin for AchievementPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<AchievementTracker>()
            .init_resource::<AchievementPopupState>()
            .add_event::<AchievementUnlockedEvent>()
            .add_systems(
                Update,
                (
                    reset_tracker_on_mission_start,
                    check_achievements.run_if(in_state(super::GameState::Playing)),
                    process_achievement_unlocks,
                )
                    .chain(),
            );
    }
}

/// Reset achievement tracker when a new mission starts
fn reset_tracker_on_mission_start(
    mut tracker: ResMut<AchievementTracker>,
    mut mission_events: EventReader<super::MissionStartEvent>,
    time: Res<Time>,
) {
    for _event in mission_events.read() {
        tracker.reset_session();
        tracker.start_mission(time.elapsed_secs_f64());
    }
}

fn in_state(state: super::GameState) -> impl FnMut(Option<Res<State<super::GameState>>>) -> bool {
    move |current: Option<Res<State<super::GameState>>>| {
        current.map(|s| *s.get() == state).unwrap_or(false)
    }
}

/// All available achievements
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Achievement {
    // === Combat Achievements ===
    /// Destroy your first enemy
    FirstBlood,
    /// Destroy 100 enemies in a single run
    Centurion,
    /// Destroy 500 enemies in a single run
    Exterminator,
    /// Destroy 1000 enemies in a single run
    Annihilator,

    // === Salt Miner/Combo Achievements ===
    /// Get a 10x combo
    ComboStarter,
    /// Get a 25x combo
    ComboKing,
    /// Get a 50x combo
    ComboMaster,
    /// Activate salt miner mode
    SaltMinerActivated,
    /// Get 10 kills while salt miner is active
    SaltMinerKiller,

    // === Liberation Achievements ===
    /// Liberate 25 souls in a single run
    Liberator,
    /// Liberate 100 souls in a single run
    FreedomFighter,
    /// Liberate 250 souls in a single run
    Emancipator,

    // === Progression Achievements ===
    /// Complete Mission 1
    FirstMission,
    /// Complete Act 1 (Missions 1-4)
    ActOneComplete,
    /// Complete Act 2 (Missions 5-9)
    ActTwoComplete,
    /// Complete Act 3 and defeat Avatar (Missions 10-13)
    CampaignVictory,
    /// Complete a mission without taking damage
    Flawless,

    // === Boss Achievements ===
    /// Defeat your first boss
    BossSlayer,
    /// Defeat the Apocalypse
    ApocalypseFallen,
    /// Defeat the Avatar titan
    TitanKiller,

    // === Score Achievements ===
    /// Score 25,000 points
    ScoreRookie,
    /// Score 50,000 points
    ScoreVeteran,
    /// Score 100,000 points
    ScoreMaster,
    /// Score 250,000 points
    ScoreLegend,

    // === Ship Achievements ===
    /// Complete a mission with the Rifter
    RifterPilot,
    /// Complete a mission with the Slasher
    SlasherPilot,
    /// Unlock a T2 ship
    T2Unlocked,

    // === Difficulty Achievements ===
    /// Complete any mission on BitterVet difficulty
    BitterVetWarrior,
    /// Complete any mission on Triglavian (Nightmare) difficulty
    TriglavianConqueror,

    // === Special/Hidden Achievements ===
    /// Get hit by a boss attack and survive with <10% health
    CloseCall,
    /// Complete a mission in under 3 minutes
    SpeedRunner,
}

impl Achievement {
    /// Display name
    pub fn name(&self) -> &'static str {
        match self {
            // Combat
            Achievement::FirstBlood => "First Blood",
            Achievement::Centurion => "Centurion",
            Achievement::Exterminator => "Exterminator",
            Achievement::Annihilator => "Annihilator",
            // Salt Miner
            Achievement::ComboStarter => "Combo Starter",
            Achievement::ComboKing => "Combo King",
            Achievement::ComboMaster => "Combo Master",
            Achievement::SaltMinerActivated => "Salt Miner",
            Achievement::SaltMinerKiller => "Salt Miner Killer",
            // Liberation
            Achievement::Liberator => "Liberator",
            Achievement::FreedomFighter => "Freedom Fighter",
            Achievement::Emancipator => "Emancipator",
            // Progression
            Achievement::FirstMission => "First Mission",
            Achievement::ActOneComplete => "Act I Complete",
            Achievement::ActTwoComplete => "Act II Complete",
            Achievement::CampaignVictory => "Campaign Victory",
            Achievement::Flawless => "Flawless",
            // Boss
            Achievement::BossSlayer => "Boss Slayer",
            Achievement::ApocalypseFallen => "Apocalypse Fallen",
            Achievement::TitanKiller => "Titan Killer",
            // Score
            Achievement::ScoreRookie => "Score Rookie",
            Achievement::ScoreVeteran => "Score Veteran",
            Achievement::ScoreMaster => "Score Master",
            Achievement::ScoreLegend => "Score Legend",
            // Ship
            Achievement::RifterPilot => "Rifter Pilot",
            Achievement::SlasherPilot => "Slasher Pilot",
            Achievement::T2Unlocked => "T2 Unlocked",
            // Difficulty
            Achievement::BitterVetWarrior => "Bitter Vet Warrior",
            Achievement::TriglavianConqueror => "Triglavian Conqueror",
            // Special
            Achievement::CloseCall => "Close Call",
            Achievement::SpeedRunner => "Speed Runner",
        }
    }

    /// Achievement description
    pub fn description(&self) -> &'static str {
        match self {
            // Combat
            Achievement::FirstBlood => "Destroy your first enemy",
            Achievement::Centurion => "Destroy 100 enemies in a single run",
            Achievement::Exterminator => "Destroy 500 enemies in a single run",
            Achievement::Annihilator => "Destroy 1000 enemies in a single run",
            // Salt Miner
            Achievement::ComboStarter => "Get a 10x combo",
            Achievement::ComboKing => "Get a 25x combo",
            Achievement::ComboMaster => "Get a 50x combo",
            Achievement::SaltMinerActivated => "Activate salt miner mode",
            Achievement::SaltMinerKiller => "Get 10 kills while salt miner is active",
            // Liberation
            Achievement::Liberator => "Liberate 25 souls in a single run",
            Achievement::FreedomFighter => "Liberate 100 souls in a single run",
            Achievement::Emancipator => "Liberate 250 souls in a single run",
            // Progression
            Achievement::FirstMission => "Complete your first mission",
            Achievement::ActOneComplete => "Complete Act I - Liberation Begins",
            Achievement::ActTwoComplete => "Complete Act II - Reclaiming Freedom",
            Achievement::CampaignVictory => "Defeat the Avatar and complete the campaign",
            Achievement::Flawless => "Complete a mission without taking damage",
            // Boss
            Achievement::BossSlayer => "Defeat your first boss",
            Achievement::ApocalypseFallen => "Defeat an Apocalypse-class battleship",
            Achievement::TitanKiller => "Defeat the Avatar titan",
            // Score
            Achievement::ScoreRookie => "Score 25,000 points in a single run",
            Achievement::ScoreVeteran => "Score 50,000 points in a single run",
            Achievement::ScoreMaster => "Score 100,000 points in a single run",
            Achievement::ScoreLegend => "Score 250,000 points in a single run",
            // Ship
            Achievement::RifterPilot => "Complete a mission with the Rifter",
            Achievement::SlasherPilot => "Complete a mission with the Slasher",
            Achievement::T2Unlocked => "Unlock a Tech 2 assault frigate",
            // Difficulty
            Achievement::BitterVetWarrior => "Complete a mission on BitterVet difficulty",
            Achievement::TriglavianConqueror => "Complete a mission on Triglavian difficulty",
            // Special
            Achievement::CloseCall => "Survive a boss hit with less than 10% health",
            Achievement::SpeedRunner => "Complete a mission in under 3 minutes",
        }
    }

    /// Whether this achievement is hidden until unlocked
    pub fn is_hidden(&self) -> bool {
        matches!(
            self,
            Achievement::CloseCall
                | Achievement::SpeedRunner
                | Achievement::Annihilator
                | Achievement::TitanKiller
                | Achievement::TriglavianConqueror
        )
    }

    /// Achievement color for UI
    pub fn color(&self) -> Color {
        match self {
            // Gold for major achievements
            Achievement::CampaignVictory
            | Achievement::TitanKiller
            | Achievement::ScoreLegend
            | Achievement::ComboMaster
            | Achievement::TriglavianConqueror => Color::srgb(1.0, 0.85, 0.2),

            // Silver for mid-tier
            Achievement::ActOneComplete
            | Achievement::ActTwoComplete
            | Achievement::ScoreMaster
            | Achievement::ComboKing
            | Achievement::Exterminator
            | Achievement::Emancipator => Color::srgb(0.8, 0.8, 0.9),

            // Bronze for entry-level
            _ => Color::srgb(0.8, 0.5, 0.3),
        }
    }

    /// Get all achievements
    pub fn all() -> &'static [Achievement] {
        &[
            Achievement::FirstBlood,
            Achievement::Centurion,
            Achievement::Exterminator,
            Achievement::Annihilator,
            Achievement::ComboStarter,
            Achievement::ComboKing,
            Achievement::ComboMaster,
            Achievement::SaltMinerActivated,
            Achievement::SaltMinerKiller,
            Achievement::Liberator,
            Achievement::FreedomFighter,
            Achievement::Emancipator,
            Achievement::FirstMission,
            Achievement::ActOneComplete,
            Achievement::ActTwoComplete,
            Achievement::CampaignVictory,
            Achievement::Flawless,
            Achievement::BossSlayer,
            Achievement::ApocalypseFallen,
            Achievement::TitanKiller,
            Achievement::ScoreRookie,
            Achievement::ScoreVeteran,
            Achievement::ScoreMaster,
            Achievement::ScoreLegend,
            Achievement::RifterPilot,
            Achievement::SlasherPilot,
            Achievement::T2Unlocked,
            Achievement::BitterVetWarrior,
            Achievement::TriglavianConqueror,
            Achievement::CloseCall,
            Achievement::SpeedRunner,
        ]
    }
}

/// Runtime achievement tracking resource
#[derive(Resource, Default)]
pub struct AchievementTracker {
    /// Achievements unlocked this session (for notifications)
    pub pending_notifications: Vec<Achievement>,
    /// Session stats for checking achievements
    pub session_kills: u32,
    pub session_souls: u32,
    pub session_max_combo: u32,
    pub session_salt_miner_kills: u32,
    pub session_bosses_killed: u32,
    pub mission_start_time: Option<f64>,
    pub took_damage_this_mission: bool,
}

impl AchievementTracker {
    /// Reset session stats (call at mission start)
    pub fn reset_session(&mut self) {
        self.session_kills = 0;
        self.session_souls = 0;
        self.session_max_combo = 0;
        self.session_salt_miner_kills = 0;
        self.session_bosses_killed = 0;
        self.mission_start_time = None;
        self.took_damage_this_mission = false;
    }

    /// Start mission timer
    pub fn start_mission(&mut self, time: f64) {
        self.mission_start_time = Some(time);
        self.took_damage_this_mission = false;
    }

    /// Get mission duration in seconds
    pub fn mission_duration(&self, current_time: f64) -> f64 {
        self.mission_start_time
            .map(|start| current_time - start)
            .unwrap_or(0.0)
    }
}

/// Event fired when an achievement is unlocked
#[derive(Event)]
pub struct AchievementUnlockedEvent {
    /// The achievement that was unlocked (available for external listeners)
    #[allow(dead_code)]
    pub achievement: Achievement,
}

/// Check achievements based on game state
fn check_achievements(
    mut tracker: ResMut<AchievementTracker>,
    mut save: ResMut<super::SaveData>,
    score: Res<super::ScoreSystem>,
    salt_miner: Res<super::SaltMinerSystem>,
    heat_system: Res<crate::systems::ComboHeatSystem>,
    mut unlock_events: EventWriter<AchievementUnlockedEvent>,
    mut enemy_events: EventReader<super::EnemyDestroyedEvent>,
    mut boss_events: EventReader<super::BossDefeatedEvent>,
    mut salt_miner_activated: EventReader<super::SaltMinerActivatedEvent>,
    mut stage_events: EventReader<super::StageCompleteEvent>,
    mut damage_events: EventReader<super::PlayerDamagedEvent>,
    time: Res<Time>,
    difficulty: Res<super::Difficulty>,
    session: Res<super::GameSession>,
) {
    // Track damage taken
    for _ in damage_events.read() {
        tracker.took_damage_this_mission = true;
    }

    // Track kills
    for event in enemy_events.read() {
        tracker.session_kills += 1;

        // First kill
        try_unlock(
            Achievement::FirstBlood,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );

        // Kill milestones
        if tracker.session_kills >= 100 {
            try_unlock(
                Achievement::Centurion,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if tracker.session_kills >= 500 {
            try_unlock(
                Achievement::Exterminator,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if tracker.session_kills >= 1000 {
            try_unlock(
                Achievement::Annihilator,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Track salt miner kills
        if salt_miner.is_active {
            tracker.session_salt_miner_kills += 1;
            if tracker.session_salt_miner_kills >= 10 {
                try_unlock(
                    Achievement::SaltMinerKiller,
                    &mut save,
                    &mut tracker,
                    &mut unlock_events,
                );
            }
        }

        // Boss kills
        if event.was_boss {
            tracker.session_bosses_killed += 1;
            try_unlock(
                Achievement::BossSlayer,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );

            // Check for specific boss types
            if event.enemy_type.contains("Apocalypse") {
                try_unlock(
                    Achievement::ApocalypseFallen,
                    &mut save,
                    &mut tracker,
                    &mut unlock_events,
                );
            }
            if event.enemy_type.contains("Avatar") {
                try_unlock(
                    Achievement::TitanKiller,
                    &mut save,
                    &mut tracker,
                    &mut unlock_events,
                );
            }
        }
    }

    // Track boss defeats from BossDefeatedEvent
    for event in boss_events.read() {
        try_unlock(
            Achievement::BossSlayer,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
        if event.boss_type.contains("Apocalypse") {
            try_unlock(
                Achievement::ApocalypseFallen,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if event.boss_type.contains("Avatar") {
            try_unlock(
                Achievement::TitanKiller,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
    }

    // Track salt miner activation
    for _ in salt_miner_activated.read() {
        try_unlock(
            Achievement::SaltMinerActivated,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }

    // Track combo
    let current_combo = heat_system.combo_count;
    if current_combo > tracker.session_max_combo {
        tracker.session_max_combo = current_combo;
    }
    if tracker.session_max_combo >= 10 {
        try_unlock(
            Achievement::ComboStarter,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if tracker.session_max_combo >= 25 {
        try_unlock(
            Achievement::ComboKing,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if tracker.session_max_combo >= 50 {
        try_unlock(
            Achievement::ComboMaster,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }

    // Track souls liberated
    let souls = score.souls_liberated;
    tracker.session_souls = souls;
    if souls >= 25 {
        try_unlock(
            Achievement::Liberator,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if souls >= 100 {
        try_unlock(
            Achievement::FreedomFighter,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if souls >= 250 {
        try_unlock(
            Achievement::Emancipator,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }

    // Track score
    let current_score = score.score;
    if current_score >= 25000 {
        try_unlock(
            Achievement::ScoreRookie,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if current_score >= 50000 {
        try_unlock(
            Achievement::ScoreVeteran,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if current_score >= 100000 {
        try_unlock(
            Achievement::ScoreMaster,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }
    if current_score >= 250000 {
        try_unlock(
            Achievement::ScoreLegend,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );
    }

    // Track stage completion
    for event in stage_events.read() {
        // First mission
        try_unlock(
            Achievement::FirstMission,
            &mut save,
            &mut tracker,
            &mut unlock_events,
        );

        // Act completion (based on stage number)
        if event.stage_number >= 4 {
            try_unlock(
                Achievement::ActOneComplete,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if event.stage_number >= 9 {
            try_unlock(
                Achievement::ActTwoComplete,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if event.stage_number >= 13 {
            try_unlock(
                Achievement::CampaignVictory,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Flawless (no damage)
        if !tracker.took_damage_this_mission {
            try_unlock(
                Achievement::Flawless,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Speed runner (under 3 minutes)
        let duration = tracker.mission_duration(time.elapsed_secs_f64());
        if duration > 0.0 && duration < 180.0 {
            try_unlock(
                Achievement::SpeedRunner,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Difficulty achievements
        if *difficulty == super::Difficulty::BitterVet {
            try_unlock(
                Achievement::BitterVetWarrior,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if *difficulty == super::Difficulty::Triglavian {
            try_unlock(
                Achievement::TriglavianConqueror,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Ship achievements based on ship selection
        let ship_name = session.selected_ship().name;
        if ship_name == "Rifter" {
            try_unlock(
                Achievement::RifterPilot,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }
        if ship_name == "Slasher" {
            try_unlock(
                Achievement::SlasherPilot,
                &mut save,
                &mut tracker,
                &mut unlock_events,
            );
        }

        // Reset for next mission
        tracker.took_damage_this_mission = false;
        tracker.mission_start_time = Some(time.elapsed_secs_f64());
    }
}

/// Try to unlock an achievement (checks if already unlocked)
fn try_unlock(
    achievement: Achievement,
    save: &mut ResMut<super::SaveData>,
    tracker: &mut ResMut<AchievementTracker>,
    unlock_events: &mut EventWriter<AchievementUnlockedEvent>,
) {
    if !save.achievements.contains(&achievement) {
        save.achievements.insert(achievement);
        tracker.pending_notifications.push(achievement);
        unlock_events.send(AchievementUnlockedEvent { achievement });
        info!(
            "Achievement unlocked: {} - {}",
            achievement.name(),
            achievement.description()
        );
    }
}

/// Process achievement unlock notifications (display popup)
fn process_achievement_unlocks(
    mut tracker: ResMut<AchievementTracker>,
    mut popup_state: ResMut<AchievementPopupState>,
) {
    // Queue new achievements for display
    for achievement in tracker.pending_notifications.drain(..) {
        popup_state.queue.push(achievement);
    }
}

/// State for achievement popup display
#[derive(Resource, Default)]
pub struct AchievementPopupState {
    /// Queue of achievements to show
    pub queue: Vec<Achievement>,
    /// Currently displayed achievement
    pub current: Option<Achievement>,
    /// Time remaining to show current popup
    pub timer: f32,
}

impl AchievementPopupState {
    /// Duration to show each achievement popup
    pub const DISPLAY_TIME: f32 = 3.0;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn achievement_names_not_empty() {
        for achievement in Achievement::all() {
            assert!(!achievement.name().is_empty());
            assert!(!achievement.description().is_empty());
        }
    }

    #[test]
    fn achievement_all_returns_all_variants() {
        let all = Achievement::all();
        assert!(all.len() >= 30);
    }

    #[test]
    fn hidden_achievements_exist() {
        let hidden_count = Achievement::all().iter().filter(|a| a.is_hidden()).count();
        assert!(hidden_count >= 3);
    }
}
