//! Visual Effects System
//!
//! Starfield, explosions, particle effects, screen shake, engine trails.

#![allow(dead_code)]

use crate::core::*;
use crate::systems::ability::{AbilityActivatedEvent, AbilityType};
use bevy::prelude::*;
use bevy::text::{Text2d, TextColor, TextFont};

/// Maximum particles to prevent slowdown during intense combat
const MAX_EXPLOSION_PARTICLES: usize = 500;
const MAX_ENGINE_PARTICLES: usize = 200;

/// Effects plugin
pub struct EffectsPlugin;

impl Plugin for EffectsPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<ScreenShake>()
            .init_resource::<ScreenFlash>()
            .init_resource::<CameraZoom>()
            .add_systems(OnEnter(GameState::Playing), spawn_starfield)
            // Split into multiple system groups due to Bevy tuple limits
            .add_systems(
                Update,
                (
                    update_starfield,
                    update_explosions,
                    update_shockwave_rings,
                    update_explosion_flashes,
                    update_explosion_embers,
                    update_screen_shake,
                    update_screen_flash,
                    update_berserk_tint,
                    update_low_health_vignette,
                    update_camera_zoom,
                    handle_explosion_events,
                )
                    .run_if(in_state(GameState::Playing)),
            )
            .add_systems(
                Update,
                (
                    spawn_engine_trails,
                    update_engine_particles,
                    spawn_bullet_trails,
                    update_bullet_trails,
                    update_hit_flash,
                    update_damage_numbers,
                    spawn_ability_effects,
                    update_ability_effects,
                )
                    .run_if(in_state(GameState::Playing)),
            )
            .add_systems(
                Update,
                (
                    // Damage layer visual effects
                    handle_damage_layer_events,
                    update_shield_ripples,
                    update_armor_sparks,
                    update_hull_fire,
                )
                    .run_if(in_state(GameState::Playing)),
            )
            .add_systems(
                Update,
                (
                    // Pickup visual effects
                    handle_pickup_effect_events,
                    update_pickup_flashes,
                    update_pickup_shockwaves,
                    update_pickup_particles,
                )
                    .run_if(in_state(GameState::Playing)),
            )
            .add_systems(
                Update,
                (
                    // Active buff visual effects on player
                    update_active_buff_visuals,
                    update_overdrive_speed_lines,
                    update_damage_boost_aura,
                )
                    .run_if(in_state(GameState::Playing)),
            )
            .add_systems(
                OnExit(GameState::Playing),
                (cleanup_effects, cleanup_effects_2, cleanup_buff_visuals),
            );
    }
}

// =============================================================================
// STARFIELD
// =============================================================================

/// Marker for star entities
#[derive(Component)]
pub struct Star {
    pub speed: f32,
    pub layer: u8,
}

/// Spawn scrolling starfield background
fn spawn_starfield(mut commands: Commands) {
    let mut rng = fastrand::Rng::new();

    // Spawn stars in 3 layers (parallax)
    for layer in 0..3 {
        let count = match layer {
            0 => 30, // Far stars (dim, slow)
            1 => 50, // Mid stars
            _ => 70, // Near stars (bright, fast)
        };

        let (speed, size, alpha) = match layer {
            0 => (20.0, 1.0, 0.3),
            1 => (40.0, 1.5, 0.5),
            _ => (80.0, 2.5, 0.8),
        };

        for _ in 0..count {
            let x = rng.f32() * SCREEN_WIDTH - SCREEN_WIDTH / 2.0;
            let y = rng.f32() * SCREEN_HEIGHT - SCREEN_HEIGHT / 2.0;

            commands.spawn((
                Star { speed, layer },
                Sprite {
                    color: Color::srgba(0.8, 0.85, 1.0, alpha),
                    custom_size: Some(Vec2::splat(size)),
                    ..default()
                },
                Transform::from_xyz(x, y, layer as f32),
            ));
        }
    }
}

/// Scroll stars downward
fn update_starfield(time: Res<Time>, mut query: Query<(&mut Transform, &Star)>) {
    let dt = time.delta_secs();

    for (mut transform, star) in query.iter_mut() {
        transform.translation.y -= star.speed * dt;

        // Wrap around
        if transform.translation.y < -SCREEN_HEIGHT / 2.0 - 10.0 {
            transform.translation.y = SCREEN_HEIGHT / 2.0 + 10.0;
            transform.translation.x = fastrand::f32() * SCREEN_WIDTH - SCREEN_WIDTH / 2.0;
        }
    }
}

// =============================================================================
// EXPLOSIONS
// =============================================================================

/// Explosion particle
#[derive(Component)]
pub struct ExplosionParticle {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Shockwave ring - expanding circular ring effect
#[derive(Component)]
pub struct ShockwaveRing {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub max_radius: f32,
}

/// Explosion flash - bright center glow
#[derive(Component)]
pub struct ExplosionFlash {
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Explosion ember - slow-moving sparks/debris
#[derive(Component)]
pub struct ExplosionEmber {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Handle explosion events with particle cap
fn handle_explosion_events(
    mut commands: Commands,
    mut events: EventReader<ExplosionEvent>,
    particle_query: Query<&ExplosionParticle>,
    mut rumble_events: EventWriter<super::RumbleRequest>,
) {
    let current_count = particle_query.iter().count();
    let mut spawned = 0;

    for event in events.read() {
        // Check particle cap before spawning
        if current_count + spawned < MAX_EXPLOSION_PARTICLES {
            let new_count =
                spawn_explosion_capped(&mut commands, event.position, &event.size, event.color);
            spawned += new_count;

            // Trigger rumble based on explosion size (only for large+ explosions to avoid spam)
            match event.size {
                ExplosionSize::Large => {
                    rumble_events.send(super::RumbleRequest::explosion());
                }
                ExplosionSize::Massive => {
                    rumble_events.send(super::RumbleRequest::big_explosion());
                }
                _ => {} // No rumble for tiny/small/medium (too spammy)
            }
        }
    }
}

/// Spawn explosion particles (returns count spawned)
fn spawn_explosion_capped(
    commands: &mut Commands,
    position: Vec2,
    size: &ExplosionSize,
    color: Color,
) -> usize {
    let (count, speed, lifetime, particle_size) = match size {
        ExplosionSize::Tiny => (5, 50.0, 0.2, 3.0),
        ExplosionSize::Small => (12, 100.0, 0.4, 5.0),
        ExplosionSize::Medium => (20, 150.0, 0.5, 7.0),
        ExplosionSize::Large => (30, 200.0, 0.6, 10.0),
        ExplosionSize::Massive => (50, 300.0, 0.8, 15.0),
    };

    let mut rng = fastrand::Rng::new();

    // Main explosion particles - hot colors in center, cooler at edges
    for i in 0..count {
        let angle = rng.f32() * std::f32::consts::TAU;
        let speed_var = speed * (0.5 + rng.f32() * 0.5);
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed_var;

        // Color gradient: inner particles are brighter/hotter
        let inner_factor = 1.0 - (i as f32 / count as f32);
        let color_var = if inner_factor > 0.5 {
            // Inner particles: white/yellow hot core
            Color::srgba(
                1.0,
                0.9 + rng.f32() * 0.1,
                0.5 + rng.f32() * 0.3,
                1.0,
            )
        } else {
            // Outer particles: orange/red
            Color::srgba(
                color.to_srgba().red * (0.8 + rng.f32() * 0.4),
                color.to_srgba().green * (0.5 + rng.f32() * 0.3),
                color.to_srgba().blue * (0.2 + rng.f32() * 0.2),
                1.0,
            )
        };

        commands.spawn((
            ExplosionParticle {
                velocity,
                lifetime,
                max_lifetime: lifetime,
            },
            Sprite {
                color: color_var,
                custom_size: Some(Vec2::splat(particle_size * (0.5 + rng.f32() * 0.5))),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS),
        ));
    }

    // Spawn shockwave ring for medium+ explosions
    if matches!(size, ExplosionSize::Medium | ExplosionSize::Large | ExplosionSize::Massive) {
        let ring_lifetime = match size {
            ExplosionSize::Medium => 0.3,
            ExplosionSize::Large => 0.4,
            ExplosionSize::Massive => 0.5,
            _ => 0.3,
        };
        let ring_radius = match size {
            ExplosionSize::Medium => 60.0,
            ExplosionSize::Large => 100.0,
            ExplosionSize::Massive => 150.0,
            _ => 60.0,
        };

        commands.spawn((
            ShockwaveRing {
                lifetime: ring_lifetime,
                max_lifetime: ring_lifetime,
                max_radius: ring_radius,
            },
            Sprite {
                color: Color::srgba(1.0, 0.8, 0.4, 0.8),
                custom_size: Some(Vec2::splat(10.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 0.1),
        ));
    }

    // Spawn center flash for small+ explosions
    if !matches!(size, ExplosionSize::Tiny) {
        let flash_lifetime = match size {
            ExplosionSize::Small => 0.1,
            ExplosionSize::Medium => 0.15,
            ExplosionSize::Large => 0.2,
            ExplosionSize::Massive => 0.25,
            _ => 0.1,
        };
        let flash_size = match size {
            ExplosionSize::Small => 20.0,
            ExplosionSize::Medium => 35.0,
            ExplosionSize::Large => 50.0,
            ExplosionSize::Massive => 80.0,
            _ => 20.0,
        };

        commands.spawn((
            ExplosionFlash {
                lifetime: flash_lifetime,
                max_lifetime: flash_lifetime,
            },
            Sprite {
                color: Color::srgba(1.0, 1.0, 0.9, 1.0), // Bright white-yellow
                custom_size: Some(Vec2::splat(flash_size)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 0.2),
        ));
    }

    // Spawn embers/sparks for medium+ explosions
    if matches!(size, ExplosionSize::Medium | ExplosionSize::Large | ExplosionSize::Massive) {
        let ember_count = match size {
            ExplosionSize::Medium => 5,
            ExplosionSize::Large => 8,
            ExplosionSize::Massive => 12,
            _ => 5,
        };

        for _ in 0..ember_count {
            let angle = rng.f32() * std::f32::consts::TAU;
            let ember_speed = speed * 0.3 * (0.5 + rng.f32() * 0.5);
            let velocity = Vec2::new(angle.cos(), angle.sin()) * ember_speed;

            commands.spawn((
                ExplosionEmber {
                    velocity,
                    lifetime: lifetime * 2.0, // Embers last longer
                    max_lifetime: lifetime * 2.0,
                },
                Sprite {
                    color: Color::srgba(1.0, 0.6 + rng.f32() * 0.3, 0.1, 1.0), // Orange-yellow sparks
                    custom_size: Some(Vec2::splat(2.0 + rng.f32() * 2.0)),
                    ..default()
                },
                Transform::from_xyz(position.x, position.y, LAYER_EFFECTS - 0.1),
            ));
        }
    }

    count
}

/// Spawn explosion particles (legacy public API)
pub fn spawn_explosion(
    commands: &mut Commands,
    position: Vec2,
    size: &ExplosionSize,
    color: Color,
) {
    spawn_explosion_capped(commands, position, size, color);
}

/// Update explosion particles
fn update_explosions(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut Transform, &mut ExplosionParticle, &mut Sprite)>,
) {
    let dt = time.delta_secs();

    for (entity, mut transform, mut particle, mut sprite) in query.iter_mut() {
        // Move
        transform.translation.x += particle.velocity.x * dt;
        transform.translation.y += particle.velocity.y * dt;

        // Slow down
        particle.velocity *= 1.0 - 3.0 * dt;

        // Fade out
        particle.lifetime -= dt;
        let alpha = (particle.lifetime / particle.max_lifetime).max(0.0);
        sprite.color = sprite.color.with_alpha(alpha);

        // Shrink
        if let Some(size) = sprite.custom_size {
            sprite.custom_size = Some(size * (1.0 - 0.5 * dt));
        }

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

/// Update shockwave rings - expand and fade
fn update_shockwave_rings(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut ShockwaveRing, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut ring, mut sprite, mut transform) in query.iter_mut() {
        ring.lifetime -= dt;

        let progress = 1.0 - (ring.lifetime / ring.max_lifetime);
        let current_radius = ring.max_radius * progress;

        // Expand the ring
        sprite.custom_size = Some(Vec2::splat(current_radius * 2.0));

        // Make it hollow by reducing alpha and using scale
        // Ring gets thinner as it expands
        let alpha = (1.0 - progress) * 0.6;
        sprite.color = sprite.color.with_alpha(alpha);

        // Slight upward drift for visual interest
        transform.translation.y += 10.0 * dt;

        if ring.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

/// Update explosion flashes - quick bright flash that fades
fn update_explosion_flashes(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut ExplosionFlash, &mut Sprite)>,
) {
    let dt = time.delta_secs();

    for (entity, mut flash, mut sprite) in query.iter_mut() {
        flash.lifetime -= dt;

        // Quick fade out with size pulse
        let progress = flash.lifetime / flash.max_lifetime;
        let alpha = progress * progress; // Quadratic fade for snappy feel
        sprite.color = sprite.color.with_alpha(alpha);

        // Pulse size slightly larger then shrink
        if let Some(size) = sprite.custom_size {
            let scale = 1.0 + (1.0 - progress) * 0.5; // Grows slightly as it fades
            sprite.custom_size = Some(size * (1.0 + 0.5 * dt));
            if progress < 0.5 {
                sprite.custom_size = Some(Vec2::splat(size.x * (0.8 + progress * 0.4)));
            }
            let _ = scale; // suppress warning
        }

        if flash.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

/// Update explosion embers - slow drifting sparks
fn update_explosion_embers(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut ExplosionEmber, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut ember, mut sprite, mut transform) in query.iter_mut() {
        // Move slowly
        transform.translation.x += ember.velocity.x * dt;
        transform.translation.y += ember.velocity.y * dt;

        // Gentle gravity (embers drift down slightly)
        ember.velocity.y -= 20.0 * dt;

        // Very slow deceleration
        ember.velocity *= 1.0 - 0.5 * dt;

        // Fade out
        ember.lifetime -= dt;
        let alpha = (ember.lifetime / ember.max_lifetime).max(0.0);
        sprite.color = sprite.color.with_alpha(alpha);

        // Flicker effect - random brightness variation
        let flicker = 0.7 + fastrand::f32() * 0.3;
        let base = sprite.color.to_srgba();
        sprite.color = Color::srgba(base.red * flicker, base.green * flicker, base.blue, alpha);

        if ember.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// SCREEN SHAKE
// =============================================================================

/// Screen shake state
#[derive(Resource)]
pub struct ScreenShake {
    pub intensity: f32,
    pub duration: f32,
    pub timer: f32,
    /// Global multiplier for shake intensity (0.0 = disabled, 1.0 = full)
    pub multiplier: f32,
}

impl Default for ScreenShake {
    fn default() -> Self {
        Self {
            intensity: 0.0,
            duration: 0.0,
            timer: 0.0,
            multiplier: 1.0, // Full intensity by default
        }
    }
}

impl ScreenShake {
    /// Trigger a screen shake
    pub fn trigger(&mut self, intensity: f32, duration: f32) {
        if intensity > self.intensity || self.timer <= 0.0 {
            self.intensity = intensity;
            self.duration = duration;
            self.timer = duration;
        }
    }

    /// Small shake (player hit)
    pub fn small(&mut self) {
        self.trigger(5.0, 0.15);
    }

    /// Medium shake (enemy explosion)
    pub fn medium(&mut self) {
        self.trigger(8.0, 0.2);
    }

    /// Large shake (boss phase change)
    pub fn large(&mut self) {
        self.trigger(15.0, 0.3);
    }

    /// Massive shake (boss defeat)
    pub fn massive(&mut self) {
        self.trigger(25.0, 0.5);
    }
}

/// Handle screen shake events
fn update_screen_shake(
    time: Res<Time>,
    mut shake: ResMut<ScreenShake>,
    mut camera_query: Query<&mut Transform, With<Camera2d>>,
    mut shake_events: EventReader<ScreenShakeEvent>,
) {
    // Process new shake events
    for event in shake_events.read() {
        if event.intensity > shake.intensity {
            shake.intensity = event.intensity;
            shake.duration = event.duration;
            shake.timer = event.duration;
        }
    }

    let dt = time.delta_secs();

    if shake.timer > 0.0 {
        shake.timer -= dt;

        let progress = shake.timer / shake.duration;
        // Apply global multiplier to shake intensity
        let current_intensity = shake.intensity * progress * shake.multiplier;

        if let Ok(mut transform) = camera_query.get_single_mut() {
            let offset_x = (fastrand::f32() - 0.5) * 2.0 * current_intensity;
            let offset_y = (fastrand::f32() - 0.5) * 2.0 * current_intensity;
            transform.translation.x = offset_x;
            transform.translation.y = offset_y;
        }
    } else {
        // Reset camera
        if let Ok(mut transform) = camera_query.get_single_mut() {
            transform.translation.x = 0.0;
            transform.translation.y = 0.0;
        }
    }
}

// =============================================================================
// DAMAGE NUMBERS
// =============================================================================

/// Floating damage number that rises and fades
#[derive(Component)]
pub struct DamageNumber {
    /// Upward velocity
    pub velocity: Vec2,
    /// Time remaining
    pub lifetime: f32,
    /// Max lifetime for fade calculation
    pub max_lifetime: f32,
}

impl DamageNumber {
    pub fn new() -> Self {
        Self {
            velocity: Vec2::new(
                (fastrand::f32() - 0.5) * 30.0, // Random horizontal drift
                80.0,                           // Rise upward
            ),
            lifetime: 0.8,
            max_lifetime: 0.8,
        }
    }
}

impl Default for DamageNumber {
    fn default() -> Self {
        Self::new()
    }
}

/// Spawn a floating damage number at position
pub fn spawn_damage_number(commands: &mut Commands, position: Vec2, damage: f32, is_crit: bool) {
    let text = format!("{:.0}", damage);
    let (color, size) = if is_crit {
        (Color::srgb(1.0, 0.9, 0.2), 18.0) // Yellow, larger for crits
    } else if damage >= 20.0 {
        (Color::srgb(1.0, 0.5, 0.2), 16.0) // Orange for heavy hits
    } else {
        (Color::srgb(1.0, 1.0, 1.0), 14.0) // White for normal
    };

    commands.spawn((
        DamageNumber::new(),
        Text2d::new(text),
        TextFont {
            font_size: size,
            ..default()
        },
        TextColor(color),
        Transform::from_xyz(position.x, position.y + 20.0, LAYER_EFFECTS + 5.0),
    ));
}

/// Update damage number positions and fade
fn update_damage_numbers(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut Transform, &mut DamageNumber, &mut TextColor)>,
) {
    let dt = time.delta_secs();

    for (entity, mut transform, mut dmg, mut color) in query.iter_mut() {
        // Move upward
        transform.translation.x += dmg.velocity.x * dt;
        transform.translation.y += dmg.velocity.y * dt;

        // Slow down horizontal drift
        dmg.velocity.x *= 1.0 - 3.0 * dt;

        // Update lifetime
        dmg.lifetime -= dt;
        let alpha = (dmg.lifetime / dmg.max_lifetime).max(0.0);

        // Fade out
        color.0 = color.0.with_alpha(alpha);

        // Scale up slightly as it rises
        let scale = 1.0 + (1.0 - alpha) * 0.3;
        transform.scale = Vec3::splat(scale);

        if dmg.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// HIT FLASH
// =============================================================================

/// Component that makes a sprite flash white when damaged
#[derive(Component)]
pub struct HitFlash {
    /// Time remaining for flash effect
    pub timer: f32,
    /// Total duration of flash
    pub duration: f32,
    /// Original sprite color (to restore after flash)
    pub original_color: Color,
}

impl HitFlash {
    /// Create a new hit flash effect
    pub fn new(original_color: Color) -> Self {
        Self {
            timer: 0.1,
            duration: 0.1,
            original_color,
        }
    }

    /// Create a hit flash with custom duration
    pub fn with_duration(original_color: Color, duration: f32) -> Self {
        Self {
            timer: duration,
            duration,
            original_color,
        }
    }
}

/// Update hit flash effects on sprites
fn update_hit_flash(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut Sprite, &mut HitFlash)>,
) {
    let dt = time.delta_secs();

    for (entity, mut sprite, mut flash) in query.iter_mut() {
        flash.timer -= dt;

        if flash.timer > 0.0 {
            // Lerp from white to original color
            let progress = 1.0 - (flash.timer / flash.duration);
            let white = Color::WHITE;
            let original = flash.original_color;

            // Simple lerp between white and original
            let r = white.to_srgba().red * (1.0 - progress) + original.to_srgba().red * progress;
            let g =
                white.to_srgba().green * (1.0 - progress) + original.to_srgba().green * progress;
            let b = white.to_srgba().blue * (1.0 - progress) + original.to_srgba().blue * progress;
            let a = original.to_srgba().alpha;

            sprite.color = Color::srgba(r, g, b, a);
        } else {
            // Flash complete, restore original and remove component
            sprite.color = flash.original_color;
            commands.entity(entity).remove::<HitFlash>();
        }
    }
}

// =============================================================================
// SCREEN FLASH
// =============================================================================

/// Screen-wide flash effect for big explosions
#[derive(Resource, Default)]
pub struct ScreenFlash {
    /// Current flash intensity (0.0 - 1.0)
    pub intensity: f32,
    /// Flash color
    pub color: Color,
    /// Fade speed
    pub fade_speed: f32,
}

impl ScreenFlash {
    /// Trigger a white screen flash
    pub fn white(&mut self, intensity: f32) {
        self.intensity = intensity.min(1.0);
        self.color = Color::WHITE;
        self.fade_speed = 4.0;
    }

    /// Trigger a colored screen flash
    pub fn colored(&mut self, color: Color, intensity: f32) {
        self.intensity = intensity.min(1.0);
        self.color = color;
        self.fade_speed = 4.0;
    }

    /// Trigger flash for massive explosion (boss kill)
    pub fn massive(&mut self) {
        self.white(0.8);
        self.fade_speed = 2.0; // Slower fade for dramatic effect
    }

    /// Trigger flash for large explosion
    pub fn large(&mut self) {
        self.white(0.5);
    }

    /// Trigger red flash for berserk activation
    pub fn berserk(&mut self) {
        self.colored(Color::srgb(1.0, 0.2, 0.2), 0.6);
        self.fade_speed = 3.0;
    }
}

/// Marker component for screen flash overlay sprite
#[derive(Component)]
pub struct ScreenFlashOverlay;

/// Update screen flash effect
fn update_screen_flash(
    mut commands: Commands,
    time: Res<Time>,
    mut flash: ResMut<ScreenFlash>,
    mut overlay_query: Query<(Entity, &mut Sprite), With<ScreenFlashOverlay>>,
) {
    let dt = time.delta_secs();

    if flash.intensity > 0.0 {
        // Fade out
        flash.intensity = (flash.intensity - flash.fade_speed * dt).max(0.0);

        // Update or create overlay
        if let Ok((_, mut sprite)) = overlay_query.get_single_mut() {
            sprite.color = flash.color.with_alpha(flash.intensity);
        } else if flash.intensity > 0.01 {
            // Spawn overlay sprite covering screen
            commands.spawn((
                ScreenFlashOverlay,
                Sprite {
                    color: flash.color.with_alpha(flash.intensity),
                    custom_size: Some(Vec2::new(SCREEN_WIDTH + 100.0, SCREEN_HEIGHT + 100.0)),
                    ..default()
                },
                Transform::from_xyz(0.0, 0.0, LAYER_HUD + 10.0), // Above everything
            ));
        }
    } else {
        // Remove overlay when done
        for (entity, _) in overlay_query.iter() {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// BERSERK SCREEN TINT
// =============================================================================

/// Marker component for berserk tint overlay
#[derive(Component)]
pub struct BerserkTintOverlay;

/// Berserk screen tint effect - red tint while berserk is active
fn update_berserk_tint(
    mut commands: Commands,
    berserk: Res<BerserkSystem>,
    mut overlay_query: Query<(Entity, &mut Sprite), With<BerserkTintOverlay>>,
) {
    if berserk.is_active {
        // Pulse the tint based on remaining time
        let pulse = (berserk.timer * 8.0).sin().abs() * 0.1;
        let alpha = 0.15 + pulse;

        if let Ok((_, mut sprite)) = overlay_query.get_single_mut() {
            sprite.color = Color::srgba(1.0, 0.1, 0.1, alpha);
        } else {
            // Spawn tint overlay
            commands.spawn((
                BerserkTintOverlay,
                Sprite {
                    color: Color::srgba(1.0, 0.1, 0.1, alpha),
                    custom_size: Some(Vec2::new(SCREEN_WIDTH + 100.0, SCREEN_HEIGHT + 100.0)),
                    ..default()
                },
                Transform::from_xyz(0.0, 0.0, LAYER_HUD + 5.0), // Below flash, above game
            ));
        }
    } else {
        // Remove tint when berserk ends
        for (entity, _) in overlay_query.iter() {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// LOW HEALTH WARNING VIGNETTE
// =============================================================================

/// Marker component for low health vignette overlay
#[derive(Component)]
pub struct LowHealthVignette;

/// Low health warning vignette - pulsing red edges when health is critical
fn update_low_health_vignette(
    mut commands: Commands,
    time: Res<Time>,
    player_query: Query<&ShipStats, With<Player>>,
    mut vignette_query: Query<(Entity, &mut Sprite), With<LowHealthVignette>>,
) {
    let Ok(stats) = player_query.get_single() else {
        // Remove vignette if no player
        for (entity, _) in vignette_query.iter() {
            commands.entity(entity).despawn();
        }
        return;
    };

    // Calculate health percentage (all layers combined)
    let total_max = stats.max_shield + stats.max_armor + stats.max_hull;
    let total_current = stats.shield + stats.armor + stats.hull;
    let health_pct = total_current / total_max;

    // Show vignette below 30% health, intensity increases as health drops
    const VIGNETTE_THRESHOLD: f32 = 0.30;

    if health_pct < VIGNETTE_THRESHOLD {
        let elapsed = time.elapsed_secs();

        // Urgency increases as health drops (0 = threshold, 1 = near death)
        let urgency = 1.0 - (health_pct / VIGNETTE_THRESHOLD);

        // Pulse speed increases with urgency (2-6 Hz)
        let pulse_speed = 2.0 + urgency * 4.0;
        let pulse = (elapsed * pulse_speed * std::f32::consts::TAU).sin() * 0.5 + 0.5;

        // Alpha based on urgency and pulse
        let base_alpha = 0.1 + urgency * 0.25;
        let alpha = base_alpha + pulse * urgency * 0.15;

        if let Ok((_, mut sprite)) = vignette_query.get_single_mut() {
            sprite.color = Color::srgba(0.8, 0.0, 0.0, alpha);
        } else {
            // Spawn vignette overlay
            commands.spawn((
                LowHealthVignette,
                Sprite {
                    color: Color::srgba(0.8, 0.0, 0.0, alpha),
                    custom_size: Some(Vec2::new(SCREEN_WIDTH + 100.0, SCREEN_HEIGHT + 100.0)),
                    ..default()
                },
                Transform::from_xyz(0.0, 0.0, LAYER_HUD + 4.0), // Below berserk tint
            ));
        }
    } else {
        // Remove vignette when health is OK
        for (entity, _) in vignette_query.iter() {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// CAMERA ZOOM PULSE
// =============================================================================

/// Camera zoom pulse for dramatic moments (boss kills)
#[derive(Resource)]
pub struct CameraZoom {
    /// Target scale (1.0 = normal, 1.1 = 10% zoom in)
    pub target_scale: f32,
    /// Current scale
    pub current_scale: f32,
    /// Return speed (how fast to return to normal)
    pub return_speed: f32,
}

impl Default for CameraZoom {
    fn default() -> Self {
        Self {
            target_scale: 1.0,
            current_scale: 1.0,
            return_speed: 3.0,
        }
    }
}

impl CameraZoom {
    /// Trigger a zoom pulse (zoom in then out)
    pub fn pulse(&mut self, intensity: f32) {
        self.target_scale = 1.0 + intensity;
        self.return_speed = 3.0;
    }

    /// Quick dramatic zoom for boss kills
    pub fn boss_kill(&mut self) {
        self.pulse(0.08); // 8% zoom in
        self.return_speed = 2.0; // Slower return for drama
    }

    /// Small zoom for regular kills
    pub fn small(&mut self) {
        self.pulse(0.02);
        self.return_speed = 5.0;
    }
}

/// Update camera zoom effect
fn update_camera_zoom(
    time: Res<Time>,
    mut zoom: ResMut<CameraZoom>,
    mut camera_query: Query<&mut OrthographicProjection, With<Camera2d>>,
) {
    let dt = time.delta_secs();

    // Move current scale toward target
    if zoom.current_scale != zoom.target_scale {
        let diff = zoom.target_scale - zoom.current_scale;
        zoom.current_scale += diff * 8.0 * dt; // Fast zoom in

        // Apply to camera
        if let Ok(mut projection) = camera_query.get_single_mut() {
            projection.scale = zoom.current_scale;
        }
    }

    // Return target to 1.0 over time
    if zoom.target_scale > 1.0 {
        zoom.target_scale = (zoom.target_scale - zoom.return_speed * dt).max(1.0);
    }

    // Snap to 1.0 when close
    if (zoom.current_scale - 1.0).abs() < 0.001 && zoom.target_scale == 1.0 {
        zoom.current_scale = 1.0;
        if let Ok(mut projection) = camera_query.get_single_mut() {
            projection.scale = 1.0;
        }
    }
}

// =============================================================================
// BULLET TRAILS
// =============================================================================

/// Component for projectiles that emit trails
#[derive(Component)]
pub struct BulletTrail {
    /// Trail color
    pub color: Color,
    /// Spawn rate (particles per second)
    pub spawn_rate: f32,
    /// Timer for spawning
    pub spawn_timer: f32,
}

impl BulletTrail {
    pub fn new(color: Color) -> Self {
        Self {
            color,
            spawn_rate: 40.0,
            spawn_timer: 0.0,
        }
    }
}

/// Bullet trail particle
#[derive(Component)]
pub struct BulletTrailParticle {
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Spawn bullet trail particles from projectiles
fn spawn_bullet_trails(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(&Transform, &mut BulletTrail)>,
    particle_count: Query<&BulletTrailParticle>,
) {
    // Cap trail particles to avoid performance issues
    const MAX_TRAIL_PARTICLES: usize = 300;
    if particle_count.iter().count() >= MAX_TRAIL_PARTICLES {
        return;
    }

    let dt = time.delta_secs();

    for (transform, mut trail) in query.iter_mut() {
        trail.spawn_timer += dt;
        let spawn_interval = 1.0 / trail.spawn_rate;

        while trail.spawn_timer >= spawn_interval {
            trail.spawn_timer -= spawn_interval;

            let pos = transform.translation.truncate();
            let lifetime = 0.15;

            // Spawn fading particle
            commands.spawn((
                BulletTrailParticle {
                    lifetime,
                    max_lifetime: lifetime,
                },
                Sprite {
                    color: trail.color.with_alpha(0.6),
                    custom_size: Some(Vec2::new(3.0, 3.0)),
                    ..default()
                },
                Transform::from_xyz(pos.x, pos.y, LAYER_EFFECTS - 2.0),
            ));
        }
    }
}

/// Update bullet trail particles (fade and despawn)
fn update_bullet_trails(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut BulletTrailParticle, &mut Sprite)>,
) {
    let dt = time.delta_secs();

    for (entity, mut particle, mut sprite) in query.iter_mut() {
        particle.lifetime -= dt;

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        } else {
            // Fade out and shrink
            let alpha = (particle.lifetime / particle.max_lifetime) * 0.6;
            sprite.color = sprite.color.with_alpha(alpha);

            if let Some(size) = sprite.custom_size {
                sprite.custom_size = Some(size * (1.0 - dt * 4.0));
            }
        }
    }
}

// =============================================================================
// ENGINE TRAILS
// =============================================================================

/// Component for entities that emit engine trails
#[derive(Component)]
pub struct EngineTrail {
    /// Trail color (faction-based)
    pub color: Color,
    /// Spawn rate (particles per second)
    pub spawn_rate: f32,
    /// Timer for spawning
    pub spawn_timer: f32,
    /// Offset from entity center (engine position)
    pub offset: Vec2,
    /// Whether trail is active (moving)
    pub active: bool,
}

impl Default for EngineTrail {
    fn default() -> Self {
        Self {
            color: Color::srgba(0.4, 0.7, 1.0, 0.9), // Blue engine glow
            spawn_rate: 60.0,
            spawn_timer: 0.0,
            offset: Vec2::new(0.0, -25.0), // Behind ship
            active: true,
        }
    }
}

impl EngineTrail {
    /// Minmatar rust-orange engine
    pub fn minmatar() -> Self {
        Self {
            color: Color::srgba(1.0, 0.5, 0.2, 0.9),
            ..default()
        }
    }

    /// Amarr golden engine
    pub fn amarr() -> Self {
        Self {
            color: Color::srgba(1.0, 0.85, 0.3, 0.9),
            ..default()
        }
    }

    /// Caldari blue engine
    pub fn caldari() -> Self {
        Self {
            color: Color::srgba(0.3, 0.6, 1.0, 0.9),
            ..default()
        }
    }

    /// Gallente green engine
    pub fn gallente() -> Self {
        Self {
            color: Color::srgba(0.3, 0.9, 0.5, 0.9),
            ..default()
        }
    }

    /// Create engine trail from faction
    pub fn from_faction(faction: crate::core::Faction) -> Self {
        Self {
            color: faction.engine_color(),
            ..default()
        }
    }
}

/// Engine trail particle
#[derive(Component)]
pub struct EngineParticle {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub base_color: Color,
    pub is_core: bool, // Core particles are brighter/smaller
}

/// Spawn engine trail particles from entities with EngineTrail
fn spawn_engine_trails(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(&Transform, &mut EngineTrail)>,
) {
    let dt = time.delta_secs();

    for (transform, mut trail) in query.iter_mut() {
        if !trail.active {
            continue;
        }

        trail.spawn_timer += dt;
        let spawn_interval = 1.0 / trail.spawn_rate;

        while trail.spawn_timer >= spawn_interval {
            trail.spawn_timer -= spawn_interval;

            // Calculate spawn position with offset
            let rotation = transform.rotation.to_euler(EulerRot::ZYX).0;
            let rotated_offset = Vec2::new(
                trail.offset.x * rotation.cos() - trail.offset.y * rotation.sin(),
                trail.offset.x * rotation.sin() + trail.offset.y * rotation.cos(),
            );
            let spawn_pos = transform.translation.truncate() + rotated_offset;

            // Exhaust direction (opposite of ship facing)
            let exhaust_dir = Vec2::new(-rotation.sin(), -rotation.cos());

            // Spawn core particle (bright, small, short-lived)
            let core_spread = 2.0;
            let core_offset = Vec2::new(
                (fastrand::f32() - 0.5) * core_spread,
                (fastrand::f32() - 0.5) * core_spread,
            );
            let core_vel = exhaust_dir * (60.0 + fastrand::f32() * 30.0);
            let core_lifetime = 0.08 + fastrand::f32() * 0.06;

            commands.spawn((
                EngineParticle {
                    velocity: core_vel,
                    lifetime: core_lifetime,
                    max_lifetime: core_lifetime,
                    base_color: trail.color,
                    is_core: true,
                },
                Sprite {
                    color: Color::srgba(1.0, 1.0, 0.95, 1.0), // Hot white core
                    custom_size: Some(Vec2::new(3.0, 5.0)), // Elongated
                    ..default()
                },
                Transform::from_xyz(
                    spawn_pos.x + core_offset.x,
                    spawn_pos.y + core_offset.y,
                    LAYER_EFFECTS - 0.5,
                )
                .with_rotation(Quat::from_rotation_z(rotation)),
            ));

            // Spawn outer glow particle (faction color, larger, longer-lived)
            let glow_spread = 6.0;
            let glow_offset = Vec2::new(
                (fastrand::f32() - 0.5) * glow_spread,
                (fastrand::f32() - 0.5) * glow_spread,
            );
            let glow_vel = exhaust_dir * (40.0 + fastrand::f32() * 40.0)
                + Vec2::new(
                    (fastrand::f32() - 0.5) * 20.0,
                    (fastrand::f32() - 0.5) * 20.0,
                );
            let glow_lifetime = 0.15 + fastrand::f32() * 0.15;
            let glow_size = 4.0 + fastrand::f32() * 4.0;

            commands.spawn((
                EngineParticle {
                    velocity: glow_vel,
                    lifetime: glow_lifetime,
                    max_lifetime: glow_lifetime,
                    base_color: trail.color,
                    is_core: false,
                },
                Sprite {
                    color: trail.color.with_alpha(0.7),
                    custom_size: Some(Vec2::splat(glow_size)),
                    ..default()
                },
                Transform::from_xyz(
                    spawn_pos.x + glow_offset.x,
                    spawn_pos.y + glow_offset.y,
                    LAYER_EFFECTS - 1.0,
                ),
            ));
        }
    }
}

/// Update engine trail particles
fn update_engine_particles(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut Transform, &mut EngineParticle, &mut Sprite)>,
) {
    let dt = time.delta_secs();

    for (entity, mut transform, mut particle, mut sprite) in query.iter_mut() {
        // Move
        transform.translation.x += particle.velocity.x * dt;
        transform.translation.y += particle.velocity.y * dt;

        // Slow down (core slows faster)
        let drag = if particle.is_core { 8.0 } else { 4.0 };
        particle.velocity *= 1.0 - drag * dt;

        // Update lifetime
        particle.lifetime -= dt;
        let progress = particle.lifetime / particle.max_lifetime;

        if particle.is_core {
            // Core: fade from white to faction color, then fade out
            let base = particle.base_color.to_srgba();
            let r = 1.0 * progress + base.red * (1.0 - progress);
            let g = 1.0 * progress + base.green * (1.0 - progress);
            let b = 0.9 * progress + base.blue * (1.0 - progress);
            sprite.color = Color::srgba(r, g, b, progress);
        } else {
            // Glow: just fade out
            sprite.color = particle.base_color.with_alpha(progress * 0.7);
        }

        // Shrink
        if let Some(size) = sprite.custom_size {
            let shrink_rate = if particle.is_core { 3.0 } else { 1.5 };
            sprite.custom_size = Some(size * (1.0 - shrink_rate * dt));
        }

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// ABILITY VISUAL EFFECTS
// =============================================================================

/// Visual effect type for abilities
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AbilityEffectType {
    /// Speed boost - trailing lines
    SpeedBoost,
    /// Shield activation - expanding ring
    ShieldBubble,
    /// Armor hardening - metallic particles
    ArmorPlating,
    /// Weapon charge - energy particles
    WeaponCharge,
    /// Drone deployment - swarm particles
    DroneSwarm,
    /// Disruption - wave pulse
    Disruption,
    /// Damage boost - red aura
    DamageAura,
}

/// Component for ability visual effect particles
#[derive(Component)]
pub struct AbilityEffectParticle {
    pub effect_type: AbilityEffectType,
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
    /// For effects that orbit or rotate
    pub angle: f32,
    pub angular_velocity: f32,
}

/// Component for ability aura effect (attached to player)
#[derive(Component)]
pub struct AbilityAura {
    pub ability_type: AbilityType,
    pub timer: f32,
}

/// Spawn visual effects when ability is activated
fn spawn_ability_effects(
    mut commands: Commands,
    mut ability_events: EventReader<AbilityActivatedEvent>,
    player_query: Query<&Transform, With<crate::entities::Player>>,
    mut screen_flash: ResMut<ScreenFlash>,
) {
    for event in ability_events.read() {
        let Ok(player_transform) = player_query.get(event.player_entity) else {
            continue;
        };
        let pos = player_transform.translation.truncate();

        match event.ability_type {
            AbilityType::Overdrive | AbilityType::Afterburner => {
                // Speed boost - orange flash + trailing particles
                screen_flash.colored(Color::srgba(1.0, 0.6, 0.2, 0.8), 0.4);
                spawn_speed_boost_effect(&mut commands, pos);
            }
            AbilityType::ShieldBoost => {
                // Shield - blue expanding ring
                screen_flash.colored(Color::srgba(0.3, 0.6, 1.0, 0.8), 0.5);
                spawn_shield_effect(&mut commands, pos);
            }
            AbilityType::ArmorHardener | AbilityType::ArmorRepair => {
                // Armor - gold metallic flash
                screen_flash.colored(Color::srgba(1.0, 0.85, 0.3, 0.8), 0.4);
                spawn_armor_effect(&mut commands, pos);
            }
            AbilityType::RocketBarrage | AbilityType::Salvo | AbilityType::Scorch => {
                // Weapon - red charge particles
                screen_flash.colored(Color::srgba(1.0, 0.3, 0.2, 0.8), 0.3);
                spawn_weapon_charge_effect(&mut commands, pos);
            }
            AbilityType::DeployDrone | AbilityType::DroneBay => {
                // Drone - green swarm particles
                screen_flash.colored(Color::srgba(0.3, 1.0, 0.5, 0.8), 0.4);
                spawn_drone_effect(&mut commands, pos);
            }
            AbilityType::WarpDisruptor => {
                // Disruption - purple wave
                screen_flash.colored(Color::srgba(0.7, 0.3, 1.0, 0.8), 0.5);
                spawn_disruption_effect(&mut commands, pos);
            }
            AbilityType::CloseRange => {
                // Damage boost - red aura
                screen_flash.colored(Color::srgba(1.0, 0.2, 0.2, 0.8), 0.5);
                spawn_damage_aura_effect(&mut commands, pos);
            }
            AbilityType::None => {}
        }
    }
}

/// Spawn speed boost trailing particles
fn spawn_speed_boost_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    for i in 0..12 {
        let angle = (i as f32 / 12.0) * std::f32::consts::TAU + rng.f32() * 0.3;
        let speed = 80.0 + rng.f32() * 60.0;
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::SpeedBoost,
                velocity,
                lifetime: 0.4,
                max_lifetime: 0.4,
                angle: 0.0,
                angular_velocity: 0.0,
            },
            Sprite {
                color: Color::srgba(1.0, 0.6, 0.2, 0.9),
                custom_size: Some(Vec2::new(8.0, 3.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0)
                .with_rotation(Quat::from_rotation_z(angle)),
        ));
    }
}

/// Spawn shield bubble expanding ring
fn spawn_shield_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    // Expanding ring particles
    for i in 0..20 {
        let angle = (i as f32 / 20.0) * std::f32::consts::TAU;
        let speed = 120.0 + rng.f32() * 40.0;
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::ShieldBubble,
                velocity,
                lifetime: 0.5,
                max_lifetime: 0.5,
                angle,
                angular_velocity: 0.0,
            },
            Sprite {
                color: Color::srgba(0.4, 0.7, 1.0, 0.9),
                custom_size: Some(Vec2::splat(6.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0),
        ));
    }
}

/// Spawn armor metallic particles
fn spawn_armor_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    for _ in 0..15 {
        let angle = rng.f32() * std::f32::consts::TAU;
        let dist = 10.0 + rng.f32() * 20.0;
        let offset = Vec2::new(angle.cos(), angle.sin()) * dist;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::ArmorPlating,
                velocity: Vec2::new(0.0, 30.0 + rng.f32() * 20.0),
                lifetime: 0.6,
                max_lifetime: 0.6,
                angle: rng.f32() * std::f32::consts::TAU,
                angular_velocity: (rng.f32() - 0.5) * 8.0,
            },
            Sprite {
                color: Color::srgba(1.0, 0.85, 0.3, 0.9),
                custom_size: Some(Vec2::new(5.0, 5.0)),
                ..default()
            },
            Transform::from_xyz(
                position.x + offset.x,
                position.y + offset.y,
                LAYER_EFFECTS + 1.0,
            ),
        ));
    }
}

/// Spawn weapon charge energy particles
fn spawn_weapon_charge_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    // Inward-converging particles
    for _ in 0..16 {
        let angle = rng.f32() * std::f32::consts::TAU;
        let dist = 40.0 + rng.f32() * 20.0;
        let start_pos = position + Vec2::new(angle.cos(), angle.sin()) * dist;

        // Velocity pointing toward player
        let velocity = (position - start_pos).normalize() * (100.0 + rng.f32() * 50.0);

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::WeaponCharge,
                velocity,
                lifetime: 0.3,
                max_lifetime: 0.3,
                angle: 0.0,
                angular_velocity: 0.0,
            },
            Sprite {
                color: Color::srgba(1.0, 0.4, 0.3, 0.9),
                custom_size: Some(Vec2::splat(4.0)),
                ..default()
            },
            Transform::from_xyz(start_pos.x, start_pos.y, LAYER_EFFECTS + 1.0),
        ));
    }
}

/// Spawn drone swarm particles
fn spawn_drone_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    for _ in 0..10 {
        let angle = rng.f32() * std::f32::consts::TAU;
        let speed = 60.0 + rng.f32() * 80.0;
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::DroneSwarm,
                velocity,
                lifetime: 0.5,
                max_lifetime: 0.5,
                angle,
                angular_velocity: 3.0 + rng.f32() * 4.0,
            },
            Sprite {
                color: Color::srgba(0.4, 1.0, 0.6, 0.9),
                custom_size: Some(Vec2::new(6.0, 4.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0),
        ));
    }
}

/// Spawn disruption wave effect
fn spawn_disruption_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    // Expanding wave ring
    for i in 0..24 {
        let angle = (i as f32 / 24.0) * std::f32::consts::TAU;
        let speed = 180.0 + rng.f32() * 30.0;
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::Disruption,
                velocity,
                lifetime: 0.6,
                max_lifetime: 0.6,
                angle,
                angular_velocity: 0.0,
            },
            Sprite {
                color: Color::srgba(0.7, 0.3, 1.0, 0.8),
                custom_size: Some(Vec2::new(10.0, 4.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0)
                .with_rotation(Quat::from_rotation_z(angle)),
        ));
    }
}

/// Spawn damage aura red particles
fn spawn_damage_aura_effect(commands: &mut Commands, position: Vec2) {
    let mut rng = fastrand::Rng::new();

    for _ in 0..18 {
        let angle = rng.f32() * std::f32::consts::TAU;
        let speed = 40.0 + rng.f32() * 60.0;
        let velocity = Vec2::new(angle.cos(), angle.sin()) * speed;

        commands.spawn((
            AbilityEffectParticle {
                effect_type: AbilityEffectType::DamageAura,
                velocity,
                lifetime: 0.5,
                max_lifetime: 0.5,
                angle: 0.0,
                angular_velocity: 0.0,
            },
            Sprite {
                color: Color::srgba(1.0, 0.2, 0.2, 0.9),
                custom_size: Some(Vec2::splat(5.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0),
        ));
    }
}

/// Update ability effect particles
fn update_ability_effects(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(
        Entity,
        &mut Transform,
        &mut AbilityEffectParticle,
        &mut Sprite,
    )>,
) {
    let dt = time.delta_secs();

    for (entity, mut transform, mut particle, mut sprite) in query.iter_mut() {
        // Move
        transform.translation.x += particle.velocity.x * dt;
        transform.translation.y += particle.velocity.y * dt;

        // Rotate if applicable
        if particle.angular_velocity != 0.0 {
            particle.angle += particle.angular_velocity * dt;
            transform.rotation = Quat::from_rotation_z(particle.angle);
        }

        // Slow down
        particle.velocity *= 1.0 - 4.0 * dt;

        // Update lifetime
        particle.lifetime -= dt;
        let progress = particle.lifetime / particle.max_lifetime;

        // Fade out
        let alpha = progress * 0.9;
        sprite.color = sprite.color.with_alpha(alpha);

        // Shrink
        if let Some(size) = sprite.custom_size {
            sprite.custom_size = Some(size * (1.0 - 1.5 * dt));
        }

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
        }
    }
}

// =============================================================================
// CLEANUP
// =============================================================================

fn cleanup_effects(
    mut commands: Commands,
    stars: Query<Entity, With<Star>>,
    explosion_particles: Query<Entity, With<ExplosionParticle>>,
    engine_particles: Query<Entity, With<EngineParticle>>,
    flash_overlays: Query<Entity, With<ScreenFlashOverlay>>,
    damage_numbers: Query<Entity, With<DamageNumber>>,
    bullet_trail_particles: Query<Entity, With<BulletTrailParticle>>,
    ability_effect_particles: Query<Entity, With<AbilityEffectParticle>>,
) {
    for entity in stars.iter() {
        commands.entity(entity).despawn();
    }
    for entity in explosion_particles.iter() {
        commands.entity(entity).despawn();
    }
    for entity in engine_particles.iter() {
        commands.entity(entity).despawn();
    }
    for entity in flash_overlays.iter() {
        commands.entity(entity).despawn();
    }
    for entity in damage_numbers.iter() {
        commands.entity(entity).despawn();
    }
    for entity in bullet_trail_particles.iter() {
        commands.entity(entity).despawn();
    }
    for entity in ability_effect_particles.iter() {
        commands.entity(entity).despawn();
    }
}

fn cleanup_effects_2(
    mut commands: Commands,
    shield_ripples: Query<Entity, With<ShieldRipple>>,
    armor_sparks: Query<Entity, With<ArmorSpark>>,
    hull_fire_particles: Query<Entity, With<HullFireParticle>>,
    pickup_flashes: Query<Entity, With<PickupFlash>>,
    pickup_shockwaves: Query<Entity, With<PickupShockwave>>,
    pickup_particles: Query<Entity, With<PickupParticle>>,
    low_health_vignettes: Query<Entity, With<LowHealthVignette>>,
) {
    for entity in shield_ripples.iter() {
        commands.entity(entity).despawn();
    }
    for entity in armor_sparks.iter() {
        commands.entity(entity).despawn();
    }
    for entity in hull_fire_particles.iter() {
        commands.entity(entity).despawn();
    }
    for entity in pickup_flashes.iter() {
        commands.entity(entity).despawn();
    }
    for entity in pickup_shockwaves.iter() {
        commands.entity(entity).despawn();
    }
    for entity in pickup_particles.iter() {
        commands.entity(entity).despawn();
    }
    for entity in low_health_vignettes.iter() {
        commands.entity(entity).despawn();
    }
}

fn cleanup_buff_visuals(
    mut commands: Commands,
    invuln_shields: Query<Entity, With<InvulnShieldBubble>>,
    speed_lines: Query<Entity, With<OverdriveSpeedLine>>,
    damage_auras: Query<Entity, With<DamageBoostAura>>,
) {
    for entity in invuln_shields.iter() {
        commands.entity(entity).despawn();
    }
    for entity in speed_lines.iter() {
        commands.entity(entity).despawn();
    }
    for entity in damage_auras.iter() {
        commands.entity(entity).despawn();
    }
}

// =============================================================================
// DAMAGE LAYER VISUAL EFFECTS
// Ported from Python version - shield ripples, armor sparks, hull fire
// =============================================================================

/// Maximum damage layer particles
const MAX_DAMAGE_LAYER_PARTICLES: usize = 100;

/// Maximum shield ripple effects at once
const MAX_SHIELD_RIPPLES: usize = 15;

/// Maximum pickup effect particles at once
const MAX_PICKUP_PARTICLES: usize = 100;

/// Shield impact ripple - hexagonal expanding ring
#[derive(Component)]
pub struct ShieldRipple {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub max_radius: f32,
    pub angle: f32, // Direction of impact
}

/// Armor spark particle - directional spark spray
#[derive(Component)]
pub struct ArmorSpark {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Hull fire/smoke particle - persistent damage indicator
#[derive(Component)]
pub struct HullFireParticle {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub is_smoke: bool,
}

/// Handle damage layer events and spawn appropriate effects
fn handle_damage_layer_events(
    mut commands: Commands,
    mut events: EventReader<DamageLayerEvent>,
    spark_query: Query<&ArmorSpark>,
    ripple_query: Query<&ShieldRipple>,
    mut screen_shake: ResMut<ScreenShake>,
) {
    let current_sparks = spark_query.iter().count();
    let current_ripples = ripple_query.iter().count();

    for event in events.read() {
        match event.layer {
            DamageLayer::Shield => {
                // Cap shield ripples to prevent lag during sustained fire
                if current_ripples < MAX_SHIELD_RIPPLES {
                    spawn_shield_ripple(&mut commands, event.position, event.direction);
                }
            }
            DamageLayer::Armor => {
                if current_sparks < MAX_DAMAGE_LAYER_PARTICLES {
                    spawn_armor_sparks(&mut commands, event.position, event.direction, event.damage);
                }
            }
            DamageLayer::Hull => {
                spawn_hull_fire(&mut commands, event.position, event.damage);
                // Hull damage causes stronger screen shake
                screen_shake.trigger(6.0, 0.15);
            }
        }
    }
}

/// Spawn a shield impact ripple effect
fn spawn_shield_ripple(commands: &mut Commands, position: Vec2, direction: Vec2) {
    let angle = direction.y.atan2(direction.x);
    let lifetime = 0.4;

    // Main ripple ring
    commands.spawn((
        ShieldRipple {
            lifetime,
            max_lifetime: lifetime,
            max_radius: 60.0,
            angle,
        },
        Sprite {
            color: Color::srgba(0.3, 0.7, 1.0, 0.8), // Blue shield color
            custom_size: Some(Vec2::splat(10.0)),
            ..default()
        },
        Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0),
    ));

    // Secondary inner ripple
    commands.spawn((
        ShieldRipple {
            lifetime: lifetime * 0.8,
            max_lifetime: lifetime * 0.8,
            max_radius: 40.0,
            angle,
        },
        Sprite {
            color: Color::srgba(0.5, 0.8, 1.0, 0.6),
            custom_size: Some(Vec2::splat(8.0)),
            ..default()
        },
        Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 0.9),
    ));

    // Spawn hex grid particles at impact point
    let num_particles = 6;
    for i in 0..num_particles {
        let particle_angle = angle + (i as f32 / num_particles as f32 - 0.5) * std::f32::consts::PI * 0.5;
        let offset = Vec2::new(particle_angle.cos(), particle_angle.sin()) * 15.0;

        commands.spawn((
            ShieldRipple {
                lifetime: 0.3,
                max_lifetime: 0.3,
                max_radius: 20.0,
                angle: particle_angle,
            },
            Sprite {
                color: Color::srgba(0.4, 0.8, 1.0, 0.7),
                custom_size: Some(Vec2::splat(6.0)),
                ..default()
            },
            Transform::from_xyz(position.x + offset.x, position.y + offset.y, LAYER_EFFECTS + 0.8),
        ));
    }
}

/// Update shield ripple effects
fn update_shield_ripples(
    mut commands: Commands,
    time: Res<Time>,
    mut ripples: Query<(Entity, &mut ShieldRipple, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut ripple, mut sprite, mut transform) in ripples.iter_mut() {
        ripple.lifetime -= dt;

        if ripple.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Expand outward
        let progress = 1.0 - (ripple.lifetime / ripple.max_lifetime);
        let current_radius = ripple.max_radius * progress;
        sprite.custom_size = Some(Vec2::splat(current_radius * 2.0));

        // Fade out
        let alpha = (ripple.lifetime / ripple.max_lifetime) * 0.8;
        let current = sprite.color.to_srgba();
        sprite.color = Color::srgba(current.red, current.green, current.blue, alpha);

        // Slight rotation for visual interest
        transform.rotation = Quat::from_rotation_z(ripple.angle + progress * 0.5);
    }
}

/// Spawn armor spark particles
fn spawn_armor_sparks(commands: &mut Commands, position: Vec2, direction: Vec2, damage: f32) {
    let spark_count = (damage / 5.0).clamp(3.0, 12.0) as u32;
    let base_angle = direction.y.atan2(direction.x);

    for i in 0..spark_count {
        // Spread sparks in a cone opposite to damage direction
        let spread = (i as f32 / spark_count as f32 - 0.5) * std::f32::consts::PI * 0.6;
        let angle = base_angle + std::f32::consts::PI + spread + (fastrand::f32() - 0.5) * 0.3;
        let speed = 80.0 + fastrand::f32() * 120.0;
        let velocity = Vec2::new(angle.cos() * speed, angle.sin() * speed);

        let lifetime = 0.2 + fastrand::f32() * 0.3;

        commands.spawn((
            ArmorSpark {
                velocity,
                lifetime,
                max_lifetime: lifetime,
            },
            Sprite {
                color: Color::srgba(1.0, 0.7, 0.3, 1.0), // Orange/gold
                custom_size: Some(Vec2::new(4.0, 2.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 0.5)
                .with_rotation(Quat::from_rotation_z(angle)),
        ));
    }
}

/// Update armor spark particles
fn update_armor_sparks(
    mut commands: Commands,
    time: Res<Time>,
    mut sparks: Query<(Entity, &mut ArmorSpark, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut spark, mut sprite, mut transform) in sparks.iter_mut() {
        spark.lifetime -= dt;

        if spark.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Move with gravity
        transform.translation.x += spark.velocity.x * dt;
        transform.translation.y += spark.velocity.y * dt;
        spark.velocity.y -= 200.0 * dt; // Gravity

        // Fade and shrink
        let progress = spark.lifetime / spark.max_lifetime;
        let alpha = progress;
        let current = sprite.color.to_srgba();
        sprite.color = Color::srgba(
            current.red,
            current.green * progress, // Orange -> red as it fades
            current.blue * progress * 0.5,
            alpha,
        );

        // Shrink
        sprite.custom_size = Some(Vec2::new(4.0 * progress, 2.0 * progress));
    }
}

/// Spawn hull fire and smoke particles
fn spawn_hull_fire(commands: &mut Commands, position: Vec2, damage: f32) {
    let particle_count = (damage / 3.0).clamp(4.0, 15.0) as u32;

    for i in 0..particle_count {
        let is_smoke = i % 3 == 0; // Every 3rd particle is smoke

        let angle = fastrand::f32() * std::f32::consts::TAU;
        let speed = 20.0 + fastrand::f32() * 40.0;
        let velocity = Vec2::new(
            angle.cos() * speed * 0.3,
            speed + fastrand::f32() * 20.0, // Mostly upward
        );

        let lifetime = if is_smoke {
            0.6 + fastrand::f32() * 0.4
        } else {
            0.3 + fastrand::f32() * 0.3
        };

        let color = if is_smoke {
            Color::srgba(0.2, 0.2, 0.2, 0.7) // Dark smoke
        } else {
            Color::srgba(1.0, 0.4, 0.1, 0.9) // Orange fire
        };

        let size = if is_smoke {
            8.0 + fastrand::f32() * 6.0
        } else {
            4.0 + fastrand::f32() * 4.0
        };

        let offset = Vec2::new(
            (fastrand::f32() - 0.5) * 20.0,
            (fastrand::f32() - 0.5) * 20.0,
        );

        commands.spawn((
            HullFireParticle {
                velocity,
                lifetime,
                max_lifetime: lifetime,
                is_smoke,
            },
            Sprite {
                color,
                custom_size: Some(Vec2::splat(size)),
                ..default()
            },
            Transform::from_xyz(
                position.x + offset.x,
                position.y + offset.y,
                if is_smoke {
                    LAYER_EFFECTS + 0.3
                } else {
                    LAYER_EFFECTS + 0.4
                },
            ),
        ));
    }
}

/// Update hull fire and smoke particles
fn update_hull_fire(
    mut commands: Commands,
    time: Res<Time>,
    mut particles: Query<(Entity, &mut HullFireParticle, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut particle, mut sprite, mut transform) in particles.iter_mut() {
        particle.lifetime -= dt;

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Move upward (fire/smoke rises)
        transform.translation.x += particle.velocity.x * dt;
        transform.translation.y += particle.velocity.y * dt;

        // Slow down horizontal movement
        particle.velocity.x *= 0.95;

        let progress = particle.lifetime / particle.max_lifetime;

        if particle.is_smoke {
            // Smoke expands and fades
            let current_size = sprite.custom_size.unwrap_or(Vec2::splat(8.0));
            sprite.custom_size = Some(current_size * (1.0 + dt * 2.0)); // Expand
            sprite.color = Color::srgba(0.2, 0.2, 0.2, progress * 0.7);
        } else {
            // Fire shrinks and changes color (orange -> red -> dark)
            let current = sprite.color.to_srgba();
            sprite.color = Color::srgba(
                current.red,
                current.green * 0.95, // Yellow -> red
                current.blue * 0.9,
                progress * 0.9,
            );
            sprite.custom_size = Some(Vec2::splat(4.0 + 4.0 * progress));
        }
    }
}

// =============================================================================
// PICKUP VISUAL EFFECTS
// Multi-phase: flash -> shockwave -> particles, scaled by rarity
// =============================================================================

use crate::entities::collectible::Rarity;

/// Pickup flash - instant bright burst at collection point
#[derive(Component)]
pub struct PickupFlash {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub color: Color,
}

/// Pickup shockwave - expanding ring
#[derive(Component)]
pub struct PickupShockwave {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub max_radius: f32,
    pub color: Color,
}

/// Pickup particle - color-matched burst particle
#[derive(Component)]
pub struct PickupParticle {
    pub velocity: Vec2,
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub color: Color,
}

/// Handle pickup effect events
fn handle_pickup_effect_events(
    mut commands: Commands,
    mut events: EventReader<PickupEffectEvent>,
    particle_query: Query<&PickupParticle>,
    mut screen_shake: ResMut<ScreenShake>,
    mut screen_flash: ResMut<ScreenFlash>,
) {
    let current_particles = particle_query.iter().count();

    for event in events.read() {
        let rarity = Rarity::for_collectible(event.collectible_type);

        // Only spawn particles if under cap (always spawn flash/shockwave for feedback)
        if current_particles < MAX_PICKUP_PARTICLES {
            spawn_pickup_effects(&mut commands, event.position, event.color, rarity);
        }

        // Screen effects scale with rarity (always play these for feedback)
        match rarity {
            Rarity::Epic => {
                screen_shake.trigger(5.0, 0.12);
                screen_flash.colored(event.color, 0.3);
            }
            Rarity::Rare => {
                screen_shake.trigger(3.0, 0.08);
                screen_flash.colored(event.color, 0.2);
            }
            Rarity::Uncommon => {
                screen_shake.trigger(1.5, 0.05);
            }
            Rarity::Common => {
                // No screen shake for common pickups
            }
        }
    }
}

/// Spawn all pickup visual effects
fn spawn_pickup_effects(commands: &mut Commands, position: Vec2, color: Color, rarity: Rarity) {
    let intensity = rarity.glow_mult();
    let particle_count = rarity.orbital_count();

    // Phase 1: Instant flash
    let flash_size = 40.0 * intensity;
    let flash_lifetime = 0.1 + 0.05 * intensity;

    commands.spawn((
        PickupFlash {
            lifetime: flash_lifetime,
            max_lifetime: flash_lifetime,
            color,
        },
        Sprite {
            color: Color::srgba(1.0, 1.0, 1.0, 0.9), // Start white
            custom_size: Some(Vec2::splat(flash_size)),
            ..default()
        },
        Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 2.0),
    ));

    // Phase 2: Shockwave ring
    let shockwave_radius = 60.0 * intensity;
    let shockwave_lifetime = 0.3 + 0.1 * intensity;

    commands.spawn((
        PickupShockwave {
            lifetime: shockwave_lifetime,
            max_lifetime: shockwave_lifetime,
            max_radius: shockwave_radius,
            color,
        },
        Sprite {
            color: color.with_alpha(0.8),
            custom_size: Some(Vec2::splat(10.0)),
            ..default()
        },
        Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.5),
    ));

    // Secondary inner shockwave for rare/epic
    if matches!(rarity, Rarity::Rare | Rarity::Epic) {
        commands.spawn((
            PickupShockwave {
                lifetime: shockwave_lifetime * 0.7,
                max_lifetime: shockwave_lifetime * 0.7,
                max_radius: shockwave_radius * 0.6,
                color,
            },
            Sprite {
                color: Color::WHITE.with_alpha(0.6),
                custom_size: Some(Vec2::splat(8.0)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.6),
        ));
    }

    // Phase 3: Particle burst
    let base_speed = 100.0 * intensity;
    let particle_lifetime = 0.4 + 0.2 * intensity;

    for i in 0..particle_count {
        let angle = (i as f32 / particle_count as f32) * std::f32::consts::TAU
            + fastrand::f32() * 0.3;
        let speed = base_speed * (0.7 + fastrand::f32() * 0.6);
        let velocity = Vec2::new(angle.cos() * speed, angle.sin() * speed);

        let lifetime = particle_lifetime * (0.7 + fastrand::f32() * 0.6);
        let size = 4.0 + 3.0 * intensity * fastrand::f32();

        // Color variation - mix with white for sparkle
        let sparkle = fastrand::f32() * 0.4;
        let c = color.to_srgba();
        let particle_color = Color::srgba(
            (c.red + sparkle).min(1.0),
            (c.green + sparkle).min(1.0),
            (c.blue + sparkle).min(1.0),
            0.9,
        );

        commands.spawn((
            PickupParticle {
                velocity,
                lifetime,
                max_lifetime: lifetime,
                color: particle_color,
            },
            Sprite {
                color: particle_color,
                custom_size: Some(Vec2::splat(size)),
                ..default()
            },
            Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.0),
        ));
    }

    // Extra sparkle particles for epic rarity
    if rarity == Rarity::Epic {
        for _ in 0..6 {
            let angle = fastrand::f32() * std::f32::consts::TAU;
            let speed = base_speed * 1.5 * (0.8 + fastrand::f32() * 0.4);
            let velocity = Vec2::new(angle.cos() * speed, angle.sin() * speed);

            commands.spawn((
                PickupParticle {
                    velocity,
                    lifetime: particle_lifetime * 1.2,
                    max_lifetime: particle_lifetime * 1.2,
                    color: Color::WHITE,
                },
                Sprite {
                    color: Color::srgba(1.0, 1.0, 1.0, 1.0),
                    custom_size: Some(Vec2::splat(6.0)),
                    ..default()
                },
                Transform::from_xyz(position.x, position.y, LAYER_EFFECTS + 1.1),
            ));
        }
    }
}

/// Update pickup flash effects
fn update_pickup_flashes(
    mut commands: Commands,
    time: Res<Time>,
    mut flashes: Query<(Entity, &mut PickupFlash, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut flash, mut sprite, mut transform) in flashes.iter_mut() {
        flash.lifetime -= dt;

        if flash.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        let progress = flash.lifetime / flash.max_lifetime;

        // Expand rapidly then shrink
        let scale = if progress > 0.5 {
            // First half: expand
            1.0 + (1.0 - progress) * 2.0
        } else {
            // Second half: shrink
            progress * 2.0
        };
        transform.scale = Vec3::splat(scale);

        // Fade from white to color to transparent
        let c = flash.color.to_srgba();
        let white_blend = progress;
        sprite.color = Color::srgba(
            c.red + (1.0 - c.red) * white_blend,
            c.green + (1.0 - c.green) * white_blend,
            c.blue + (1.0 - c.blue) * white_blend,
            progress * 0.9,
        );
    }
}

/// Update pickup shockwave effects
fn update_pickup_shockwaves(
    mut commands: Commands,
    time: Res<Time>,
    mut shockwaves: Query<(Entity, &mut PickupShockwave, &mut Sprite)>,
) {
    let dt = time.delta_secs();

    for (entity, mut wave, mut sprite) in shockwaves.iter_mut() {
        wave.lifetime -= dt;

        if wave.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        let progress = 1.0 - (wave.lifetime / wave.max_lifetime);

        // Expand outward (ease-out curve)
        let ease_progress = 1.0 - (1.0 - progress).powi(2);
        let current_radius = wave.max_radius * ease_progress;
        sprite.custom_size = Some(Vec2::splat(current_radius * 2.0));

        // Fade out
        let alpha = (1.0 - progress) * 0.8;
        let c = wave.color.to_srgba();
        sprite.color = Color::srgba(c.red, c.green, c.blue, alpha);
    }
}

// =============================================================================
// ACTIVE BUFF VISUAL EFFECTS
// Visual feedback on player while buffs are active
// =============================================================================

use crate::entities::{Player, PowerupEffects, ShipStats};

/// Golden hexagonal shield bubble for invulnerability
#[derive(Component)]
pub struct InvulnShieldBubble {
    /// Animation phase for pulsing
    pub phase: f32,
    /// Rotation angle for hex pattern
    pub rotation: f32,
}

/// Speed line particle trailing behind player during overdrive
#[derive(Component)]
pub struct OverdriveSpeedLine {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub alpha: f32,
}

/// Damage aura particle orbiting player during damage boost
#[derive(Component)]
pub struct DamageBoostAura {
    /// Orbital angle around player
    pub angle: f32,
    /// Distance from player center
    pub radius: f32,
    /// Particle lifetime
    pub lifetime: f32,
    pub max_lifetime: f32,
}

/// Spawn and update active buff visuals on player
fn update_active_buff_visuals(
    mut commands: Commands,
    time: Res<Time>,
    player_query: Query<(Entity, &Transform, &PowerupEffects), With<Player>>,
    mut shield_query: Query<(Entity, &mut InvulnShieldBubble, &mut Sprite, &mut Transform), Without<Player>>,
    speed_line_query: Query<&OverdriveSpeedLine>,
    aura_query: Query<&DamageBoostAura>,
) {
    let dt = time.delta_secs();
    let elapsed = time.elapsed_secs();

    let Ok((player_entity, player_transform, effects)) = player_query.get_single() else {
        return;
    };

    let player_pos = player_transform.translation.truncate();

    // === INVULNERABILITY SHIELD BUBBLE ===
    if effects.is_invulnerable() {
        // Check if shield exists, update or spawn
        if let Ok((_, mut bubble, mut sprite, mut transform)) = shield_query.get_single_mut() {
            // Update existing shield
            bubble.phase += dt * 3.0;
            bubble.rotation += dt * 0.5;

            // Follow player
            transform.translation.x = player_pos.x;
            transform.translation.y = player_pos.y;
            transform.rotation = Quat::from_rotation_z(bubble.rotation);

            // Pulse effect
            let pulse = (bubble.phase).sin() * 0.1 + 1.0;
            let base_size = 70.0;
            sprite.custom_size = Some(Vec2::splat(base_size * pulse));

            // Color pulse (gold to white)
            let color_pulse = (bubble.phase * 2.0).sin() * 0.3 + 0.7;
            sprite.color = Color::srgba(1.0, 0.85 + color_pulse * 0.15, 0.3 + color_pulse * 0.3, 0.4);
        } else {
            // Spawn new shield bubble
            commands.spawn((
                InvulnShieldBubble {
                    phase: 0.0,
                    rotation: 0.0,
                },
                Sprite {
                    color: Color::srgba(1.0, 0.9, 0.4, 0.4),
                    custom_size: Some(Vec2::splat(70.0)),
                    ..default()
                },
                Transform::from_xyz(player_pos.x, player_pos.y, LAYER_EFFECTS + 3.0),
            ));

            // Spawn hexagon edge particles
            for i in 0..6 {
                let angle = (i as f32 / 6.0) * std::f32::consts::TAU;
                commands.spawn((
                    InvulnShieldBubble {
                        phase: angle, // Offset phase for each
                        rotation: 0.0,
                    },
                    Sprite {
                        color: Color::srgba(1.0, 0.95, 0.6, 0.6),
                        custom_size: Some(Vec2::new(25.0, 4.0)),
                        ..default()
                    },
                    Transform::from_xyz(player_pos.x, player_pos.y, LAYER_EFFECTS + 3.1)
                        .with_rotation(Quat::from_rotation_z(angle)),
                ));
            }
        }
    } else {
        // Remove shield when invuln ends
        for (entity, _, _, _) in shield_query.iter() {
            commands.entity(entity).despawn();
        }
    }

    // === OVERDRIVE SPEED LINES ===
    if effects.is_overdrive() {
        // Spawn speed lines behind player
        let current_lines = speed_line_query.iter().count();
        const MAX_SPEED_LINES: usize = 30;

        if current_lines < MAX_SPEED_LINES && fastrand::f32() < 0.6 {
            // Spawn at random position behind player
            let offset_x = (fastrand::f32() - 0.5) * 40.0;
            let offset_y = -30.0 - fastrand::f32() * 20.0;
            let lifetime = 0.2 + fastrand::f32() * 0.15;

            commands.spawn((
                OverdriveSpeedLine {
                    lifetime,
                    max_lifetime: lifetime,
                    alpha: 0.7,
                },
                Sprite {
                    color: Color::srgba(0.3, 0.9, 1.0, 0.7), // Cyan
                    custom_size: Some(Vec2::new(3.0, 15.0 + fastrand::f32() * 20.0)),
                    ..default()
                },
                Transform::from_xyz(
                    player_pos.x + offset_x,
                    player_pos.y + offset_y,
                    LAYER_EFFECTS + 2.5,
                ),
            ));
        }
    }

    // === DAMAGE BOOST AURA ===
    if effects.is_damage_boosted() {
        // Spawn orbiting particles
        let current_aura = aura_query.iter().count();
        const MAX_AURA_PARTICLES: usize = 12;

        if current_aura < MAX_AURA_PARTICLES && fastrand::f32() < 0.3 {
            let angle = fastrand::f32() * std::f32::consts::TAU;
            let radius = 35.0 + fastrand::f32() * 15.0;
            let lifetime = 0.5 + fastrand::f32() * 0.3;

            commands.spawn((
                DamageBoostAura {
                    angle,
                    radius,
                    lifetime,
                    max_lifetime: lifetime,
                },
                Sprite {
                    color: Color::srgba(1.0, 0.3, 0.2, 0.8),
                    custom_size: Some(Vec2::splat(6.0 + fastrand::f32() * 4.0)),
                    ..default()
                },
                Transform::from_xyz(
                    player_pos.x + angle.cos() * radius,
                    player_pos.y + angle.sin() * radius,
                    LAYER_EFFECTS + 2.8,
                ),
            ));
        }
    }

    // Suppress unused variable warning
    let _ = (player_entity, elapsed);
}

/// Update overdrive speed lines
fn update_overdrive_speed_lines(
    mut commands: Commands,
    time: Res<Time>,
    mut lines: Query<(Entity, &mut OverdriveSpeedLine, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut line, mut sprite, mut transform) in lines.iter_mut() {
        line.lifetime -= dt;

        if line.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Move downward (ship is moving up)
        transform.translation.y -= 400.0 * dt;

        // Fade and stretch
        let progress = line.lifetime / line.max_lifetime;
        sprite.color = sprite.color.with_alpha(progress * line.alpha);

        // Stretch as they fade
        if let Some(size) = sprite.custom_size {
            sprite.custom_size = Some(Vec2::new(size.x * 0.98, size.y * 1.02));
        }
    }
}

/// Update damage boost aura particles
fn update_damage_boost_aura(
    mut commands: Commands,
    time: Res<Time>,
    player_query: Query<(&Transform, &PowerupEffects), With<Player>>,
    mut aura: Query<(Entity, &mut DamageBoostAura, &mut Sprite, &mut Transform), Without<Player>>,
) {
    let dt = time.delta_secs();

    let Ok((player_transform, effects)) = player_query.get_single() else {
        // Despawn all aura particles if no player
        for (entity, _, _, _) in aura.iter() {
            commands.entity(entity).despawn();
        }
        return;
    };

    // If damage boost ended, despawn all particles
    if !effects.is_damage_boosted() {
        for (entity, _, _, _) in aura.iter() {
            commands.entity(entity).despawn();
        }
        return;
    }

    let player_pos = player_transform.translation.truncate();

    for (entity, mut particle, mut sprite, mut transform) in aura.iter_mut() {
        particle.lifetime -= dt;

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Orbit around player
        particle.angle += dt * 4.0; // Angular velocity
        particle.radius -= dt * 10.0; // Slowly spiral inward

        // Update position to follow player
        transform.translation.x = player_pos.x + particle.angle.cos() * particle.radius;
        transform.translation.y = player_pos.y + particle.angle.sin() * particle.radius;

        // Fade out
        let progress = particle.lifetime / particle.max_lifetime;
        let base = sprite.color.to_srgba();
        sprite.color = Color::srgba(base.red, base.green, base.blue, progress * 0.8);

        // Shrink as they approach center
        let size_factor = (particle.radius / 50.0).clamp(0.3, 1.0);
        sprite.custom_size = Some(Vec2::splat(6.0 * size_factor));
    }
}

/// Update pickup particle effects
fn update_pickup_particles(
    mut commands: Commands,
    time: Res<Time>,
    mut particles: Query<(Entity, &mut PickupParticle, &mut Sprite, &mut Transform)>,
) {
    let dt = time.delta_secs();

    for (entity, mut particle, mut sprite, mut transform) in particles.iter_mut() {
        particle.lifetime -= dt;

        if particle.lifetime <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }

        // Move with slight deceleration
        transform.translation.x += particle.velocity.x * dt;
        transform.translation.y += particle.velocity.y * dt;
        particle.velocity *= 0.96; // Slow down

        let progress = particle.lifetime / particle.max_lifetime;

        // Fade and shrink
        let c = particle.color.to_srgba();
        sprite.color = Color::srgba(c.red, c.green, c.blue, progress * 0.9);

        let current_size = sprite.custom_size.unwrap_or(Vec2::splat(4.0));
        sprite.custom_size = Some(current_size * (0.98 + progress * 0.02));
    }
}
