//! Background System
//!
//! Loads and displays background images for menus and gameplay.
//! Features a dynamic parallax starfield during gameplay.

use crate::core::*;
use bevy::prelude::*;
use rand::Rng;

/// Background plugin
pub struct BackgroundPlugin;

impl Plugin for BackgroundPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<BackgroundAssets>()
            .init_resource::<StarfieldConfig>()
            .add_systems(Startup, load_backgrounds)
            .add_systems(OnEnter(GameState::Loading), spawn_title_background)
            .add_systems(OnEnter(GameState::MainMenu), spawn_title_background)
            .add_systems(OnEnter(GameState::DifficultySelect), spawn_title_background)
            .add_systems(OnEnter(GameState::ShipSelect), spawn_title_background)
            .add_systems(OnExit(GameState::MainMenu), despawn_menu_background)
            .add_systems(OnExit(GameState::DifficultySelect), despawn_menu_background)
            .add_systems(OnExit(GameState::ShipSelect), despawn_menu_background)
            .add_systems(OnExit(GameState::Loading), despawn_menu_background)
            // Starfield for gameplay
            .add_systems(OnEnter(GameState::Playing), spawn_starfield)
            .add_systems(
                Update,
                update_starfield.run_if(in_state(GameState::Playing)),
            )
            .add_systems(OnExit(GameState::Playing), despawn_starfield);
    }
}

/// Background image assets
#[derive(Resource, Default)]
pub struct BackgroundAssets {
    pub title: Option<Handle<Image>>,
}

/// Marker for menu background sprite
#[derive(Component)]
pub struct MenuBackground;

/// Configuration for the starfield
#[derive(Resource)]
pub struct StarfieldConfig {
    /// Number of stars per layer
    pub stars_per_layer: usize,
    /// Number of parallax layers (far to near)
    pub layers: usize,
    /// Base scroll speed (pixels per second)
    pub base_speed: f32,
    /// Speed multiplier per layer (near layers move faster)
    pub layer_speed_mult: f32,
}

impl Default for StarfieldConfig {
    fn default() -> Self {
        Self {
            stars_per_layer: 80,
            layers: 3,
            base_speed: 30.0,
            layer_speed_mult: 1.8,
        }
    }
}

/// A star in the background starfield
#[derive(Component)]
pub struct BackgroundStar {
    /// Parallax layer (0 = farthest, higher = nearer) - used at spawn time
    #[allow(dead_code)]
    pub layer: usize,
    /// Scroll speed for this star
    pub speed: f32,
    /// Base brightness (0.0-1.0)
    pub brightness: f32,
    /// Twinkle phase offset
    pub twinkle_phase: f32,
}

/// Marker for the entire starfield (for cleanup)
#[derive(Component)]
pub struct Starfield;

/// Load background images
fn load_backgrounds(mut backgrounds: ResMut<BackgroundAssets>, asset_server: Res<AssetServer>) {
    backgrounds.title = Some(asset_server.load("backgrounds/title_background.png"));
    info!("Loading background images...");
}

/// Spawn title background for menus
fn spawn_title_background(
    mut commands: Commands,
    backgrounds: Res<BackgroundAssets>,
    existing: Query<Entity, With<MenuBackground>>,
    windows: Query<&Window>,
) {
    // Don't spawn if already exists
    if !existing.is_empty() {
        return;
    }

    let Some(handle) = backgrounds.title.clone() else {
        return;
    };

    let Ok(window) = windows.get_single() else {
        return;
    };

    // Spawn background sprite that covers the screen
    commands.spawn((
        MenuBackground,
        Sprite {
            image: handle,
            custom_size: Some(Vec2::new(window.width(), window.height())),
            ..default()
        },
        Transform::from_xyz(0.0, 0.0, -100.0), // Behind everything
    ));
}

/// Despawn menu background when leaving menu states
fn despawn_menu_background(mut commands: Commands, query: Query<Entity, With<MenuBackground>>) {
    for entity in query.iter() {
        commands.entity(entity).despawn();
    }
}

/// Spawn the parallax starfield for gameplay
fn spawn_starfield(mut commands: Commands, config: Res<StarfieldConfig>, windows: Query<&Window>) {
    let Ok(window) = windows.get_single() else {
        return;
    };

    let mut rng = rand::thread_rng();
    let half_width = window.width() / 2.0 + 100.0; // Extra buffer
    let half_height = window.height() / 2.0 + 100.0;

    // Spawn stars for each layer
    for layer in 0..config.layers {
        let layer_depth = layer as f32 / config.layers as f32;
        let speed = config.base_speed * config.layer_speed_mult.powi(layer as i32);

        // Stars in far layers are dimmer and smaller
        let base_brightness = 0.3 + 0.7 * layer_depth;
        let base_size = 1.0 + 2.0 * layer_depth;

        for _ in 0..config.stars_per_layer {
            let x = rng.gen_range(-half_width..half_width);
            let y = rng.gen_range(-half_height..half_height);
            let brightness = base_brightness * rng.gen_range(0.6..1.0);
            let size = base_size * rng.gen_range(0.5..1.5);
            let twinkle_phase = rng.gen_range(0.0..std::f32::consts::TAU);

            // Determine star color - mostly white/blue, occasional warm stars
            let color = if rng.gen_bool(0.85) {
                // Cool white/blue stars
                let blue_tint = rng.gen_range(0.9..1.0);
                Color::srgba(
                    brightness * 0.95,
                    brightness * 0.98,
                    brightness * blue_tint,
                    brightness,
                )
            } else if rng.gen_bool(0.5) {
                // Yellow/orange stars
                Color::srgba(
                    brightness,
                    brightness * 0.85,
                    brightness * 0.5,
                    brightness,
                )
            } else {
                // Red dwarf stars
                Color::srgba(
                    brightness,
                    brightness * 0.6,
                    brightness * 0.5,
                    brightness * 0.9,
                )
            };

            // Z position based on layer (farther back for distant stars)
            let z = -99.0 + layer as f32 * 0.1;

            commands.spawn((
                BackgroundStar {
                    layer,
                    speed,
                    brightness,
                    twinkle_phase,
                },
                Starfield,
                Sprite {
                    color,
                    custom_size: Some(Vec2::splat(size)),
                    ..default()
                },
                Transform::from_xyz(x, y, z),
            ));
        }
    }

    // Add a few larger, brighter "prominent" stars
    for _ in 0..8 {
        let x = rng.gen_range(-half_width..half_width);
        let y = rng.gen_range(-half_height..half_height);
        let brightness = rng.gen_range(0.7..1.0);
        let size = rng.gen_range(3.0..5.0);

        commands.spawn((
            BackgroundStar {
                layer: config.layers - 1,
                speed: config.base_speed * config.layer_speed_mult.powi((config.layers - 1) as i32),
                brightness,
                twinkle_phase: rng.gen_range(0.0..std::f32::consts::TAU),
            },
            Starfield,
            Sprite {
                color: Color::srgba(brightness, brightness, brightness * 0.95, brightness),
                custom_size: Some(Vec2::splat(size)),
                ..default()
            },
            Transform::from_xyz(x, y, -98.5),
        ));
    }

    info!("Spawned starfield with {} layers", config.layers);
}

/// Update starfield - scroll and twinkle
fn update_starfield(
    mut stars: Query<(&mut Transform, &mut Sprite, &BackgroundStar)>,
    time: Res<Time>,
    windows: Query<&Window>,
) {
    let Ok(window) = windows.get_single() else {
        return;
    };

    let half_height = window.height() / 2.0 + 100.0;
    let half_width = window.width() / 2.0 + 100.0;
    let dt = time.delta_secs();
    let elapsed = time.elapsed_secs();

    for (mut transform, mut sprite, star) in stars.iter_mut() {
        // Scroll downward (player flying "up" through space)
        transform.translation.y -= star.speed * dt;

        // Wrap around when off screen
        if transform.translation.y < -half_height {
            transform.translation.y = half_height;
            // Randomize x position when wrapping
            transform.translation.x = rand::thread_rng().gen_range(-half_width..half_width);
        }

        // Subtle twinkle effect
        let twinkle = 0.85 + 0.15 * (elapsed * 3.0 + star.twinkle_phase).sin();
        let alpha = star.brightness * twinkle;

        // Update alpha while preserving color
        let current = sprite.color.to_srgba();
        sprite.color = Color::srgba(current.red, current.green, current.blue, alpha);
    }
}

/// Despawn starfield when leaving gameplay
fn despawn_starfield(mut commands: Commands, stars: Query<Entity, With<Starfield>>) {
    for entity in stars.iter() {
        commands.entity(entity).despawn();
    }
    info!("Despawned starfield");
}
