//! EVE-Style Capacitor Wheel
//!
//! Exact replica of EVE Online's HUD capacitor display:
//! - Three concentric semicircular health arcs (Shield/Armor/Structure)
//! - Central capacitor with concentric rings of dashes
//! - Speed display at bottom center
//! - Percentage readouts on left
//! - Overheating status indicators

use bevy::prelude::*;
use bevy_egui::{egui, EguiContexts};
use std::f32::consts::PI;

use crate::core::*;
use crate::entities::{Movement, Player, ShipStats};
use crate::systems::ComboHeatSystem;

/// Capacitor wheel plugin
pub struct CapacitorWheelPlugin;

impl Plugin for CapacitorWheelPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<CapacitorAnimation>().add_systems(
            Update,
            (update_capacitor_animation, draw_capacitor_wheel)
                .chain()
                .run_if(in_state(GameState::Playing))
                .after(bevy_egui::EguiSet::ProcessInput),
        );
    }
}

/// Animation state for capacitor effects
#[derive(Resource)]
pub struct CapacitorAnimation {
    pub rotation: f32,
    pub pulse: f32,
    pub pulse_direction: f32,
}

impl Default for CapacitorAnimation {
    fn default() -> Self {
        Self {
            rotation: 0.0,
            pulse: 1.0,
            pulse_direction: 1.0,
        }
    }
}

/// Update capacitor animation
fn update_capacitor_animation(time: Res<Time>, mut anim: ResMut<CapacitorAnimation>) {
    let dt = time.delta_secs();

    // Very slow rotation for capacitor glow effect
    anim.rotation += dt * 0.15;
    if anim.rotation > PI * 2.0 {
        anim.rotation -= PI * 2.0;
    }

    // Subtle pulsing
    anim.pulse += anim.pulse_direction * dt * 0.5;
    if anim.pulse > 1.1 {
        anim.pulse = 1.1;
        anim.pulse_direction = -1.0;
    } else if anim.pulse < 0.9 {
        anim.pulse = 0.9;
        anim.pulse_direction = 1.0;
    }
}

/// Draw EVE-style capacitor wheel using egui
fn draw_capacitor_wheel(
    mut egui_ctx: EguiContexts,
    player_query: Query<(&ShipStats, Option<&Movement>), With<Player>>,
    heat_system: Res<ComboHeatSystem>,
    anim: Res<CapacitorAnimation>,
    windows: Query<&Window>,
) {
    let Ok((stats, movement)) = player_query.get_single() else {
        return;
    };

    let Ok(window) = windows.get_single() else {
        return;
    };

    let Some(ctx) = egui_ctx.try_ctx_mut() else {
        return;
    };

    // Position at bottom center of screen
    let wheel_radius = 55.0;
    let center_x = window.width() / 2.0;
    let center_y = window.height() - 70.0;

    // Calculate percentages
    let shield_pct = (stats.shield / stats.max_shield).clamp(0.0, 1.0);
    let armor_pct = (stats.armor / stats.max_armor).clamp(0.0, 1.0);
    let hull_pct = (stats.hull / stats.max_hull).clamp(0.0, 1.0);
    let cap_pct = (stats.capacitor / stats.max_capacitor).clamp(0.0, 1.0);
    let heat_pct = heat_system.heat / 100.0;

    // Get speed
    let speed = movement.map(|m| m.velocity.length()).unwrap_or(0.0);

    // Draw using egui Area
    egui::Area::new(egui::Id::new("capacitor_wheel"))
        .fixed_pos(egui::pos2(
            center_x - wheel_radius - 45.0,
            center_y - wheel_radius - 25.0,
        ))
        .show(ctx, |ui| {
            let size = egui::vec2((wheel_radius + 50.0) * 2.0, (wheel_radius + 40.0) * 2.0);
            let (response, painter) = ui.allocate_painter(size, egui::Sense::hover());
            let center = egui::pos2(response.rect.center().x, response.rect.center().y - 5.0);

            // === OUTER SENSOR OVERLAY RING ===
            painter.circle_stroke(
                center,
                wheel_radius + 8.0,
                egui::Stroke::new(1.0, egui::Color32::from_rgb(35, 40, 50)),
            );

            // === MAIN DARK BACKGROUND ===
            painter.circle_filled(
                center,
                wheel_radius + 3.0,
                egui::Color32::from_rgba_unmultiplied(12, 15, 22, 250),
            );
            painter.circle_stroke(
                center,
                wheel_radius + 3.0,
                egui::Stroke::new(1.5, egui::Color32::from_rgb(40, 45, 55)),
            );

            // === HEALTH ARCS (top semicircle, EVE style) ===
            let arc_width = 7.0;
            let arc_gap = 2.0;
            let arc_start = -PI; // Left
            let arc_end = 0.0;   // Right (top semicircle)

            // Shield arc (outermost) - grayish white
            let shield_radius = wheel_radius - 2.0;
            draw_eve_health_arc(
                &painter,
                center,
                shield_radius,
                arc_width,
                shield_pct,
                arc_start,
                arc_end,
                egui::Color32::from_rgb(210, 215, 225), // Filled - bright white-gray
                egui::Color32::from_rgb(35, 40, 50),    // Empty - dark
                24,
            );

            // Armor arc (middle)
            let armor_radius = shield_radius - arc_width - arc_gap;
            draw_eve_health_arc(
                &painter,
                center,
                armor_radius,
                arc_width,
                armor_pct,
                arc_start,
                arc_end,
                egui::Color32::from_rgb(195, 200, 210),
                egui::Color32::from_rgb(32, 37, 47),
                20,
            );

            // Structure/Hull arc (innermost)
            let structure_radius = armor_radius - arc_width - arc_gap;
            draw_eve_health_arc(
                &painter,
                center,
                structure_radius,
                arc_width,
                hull_pct,
                arc_start,
                arc_end,
                egui::Color32::from_rgb(180, 185, 195),
                egui::Color32::from_rgb(28, 33, 43),
                16,
            );

            // === CAPACITOR RINGS (concentric circles of dashes) ===
            let cap_inner_radius = 18.0;
            let cap_outer_radius = structure_radius - arc_width - 5.0;
            draw_capacitor_rings(
                &painter,
                center,
                cap_inner_radius,
                cap_outer_radius,
                cap_pct,
                heat_pct,
                anim.pulse,
            );

            // === INNER SPEED DISPLAY CIRCLE ===
            painter.circle_filled(
                center,
                cap_inner_radius,
                egui::Color32::from_rgba_unmultiplied(20, 28, 40, 240),
            );
            painter.circle_stroke(
                center,
                cap_inner_radius,
                egui::Stroke::new(1.0, egui::Color32::from_rgb(50, 60, 75)),
            );

            // === OVERHEATING STATUS (orange indicators above capacitor) ===
            if heat_pct > 0.0 {
                draw_heat_indicators(&painter, center, wheel_radius, heat_pct);
            }

            // === PERCENTAGE TEXT (left side, stacked) ===
            let text_x = center.x - wheel_radius - 28.0;
            let text_y_start = center.y - 25.0;
            let text_spacing = 14.0;

            // Shield %
            let shield_color = health_text_color(shield_pct);
            painter.text(
                egui::pos2(text_x, text_y_start),
                egui::Align2::RIGHT_CENTER,
                format!("{:.0}%", shield_pct * 100.0),
                egui::FontId::monospace(10.0),
                shield_color,
            );

            // Armor %
            let armor_color = health_text_color(armor_pct);
            painter.text(
                egui::pos2(text_x, text_y_start + text_spacing),
                egui::Align2::RIGHT_CENTER,
                format!("{:.0}%", armor_pct * 100.0),
                egui::FontId::monospace(10.0),
                armor_color,
            );

            // Hull %
            let hull_color = health_text_color(hull_pct);
            painter.text(
                egui::pos2(text_x, text_y_start + text_spacing * 2.0),
                egui::Align2::RIGHT_CENTER,
                format!("{:.0}%", hull_pct * 100.0),
                egui::FontId::monospace(10.0),
                hull_color,
            );

            // === SPEED DISPLAY (center) ===
            painter.text(
                egui::pos2(center.x, center.y + 2.0),
                egui::Align2::CENTER_CENTER,
                format!("{:.0}", speed),
                egui::FontId::monospace(11.0),
                egui::Color32::from_rgb(100, 170, 210),
            );
            painter.text(
                egui::pos2(center.x, center.y + 14.0),
                egui::Align2::CENTER_CENTER,
                "m/s",
                egui::FontId::monospace(7.0),
                egui::Color32::from_rgb(70, 100, 130),
            );

            // === -/+ SPEED CONTROL INDICATORS ===
            let ctrl_y = center.y + wheel_radius + 12.0;

            // Minus button (left)
            painter.circle_filled(
                egui::pos2(center.x - 22.0, ctrl_y),
                8.0,
                egui::Color32::from_rgb(30, 35, 45),
            );
            painter.circle_stroke(
                egui::pos2(center.x - 22.0, ctrl_y),
                8.0,
                egui::Stroke::new(1.0, egui::Color32::from_rgb(55, 65, 80)),
            );
            painter.text(
                egui::pos2(center.x - 22.0, ctrl_y),
                egui::Align2::CENTER_CENTER,
                "−",
                egui::FontId::proportional(14.0),
                egui::Color32::from_rgb(140, 150, 165),
            );

            // Plus button (right)
            painter.circle_filled(
                egui::pos2(center.x + 22.0, ctrl_y),
                8.0,
                egui::Color32::from_rgb(30, 35, 45),
            );
            painter.circle_stroke(
                egui::pos2(center.x + 22.0, ctrl_y),
                8.0,
                egui::Stroke::new(1.0, egui::Color32::from_rgb(55, 65, 80)),
            );
            painter.text(
                egui::pos2(center.x + 22.0, ctrl_y),
                egui::Align2::CENTER_CENTER,
                "+",
                egui::FontId::proportional(14.0),
                egui::Color32::from_rgb(140, 150, 165),
            );

            // Speed value below center
            painter.text(
                egui::pos2(center.x, ctrl_y),
                egui::Align2::CENTER_CENTER,
                format!("{:.0} m/s", speed),
                egui::FontId::monospace(9.0),
                egui::Color32::from_rgb(80, 140, 180),
            );
        });
}

/// Get text color based on health percentage
fn health_text_color(pct: f32) -> egui::Color32 {
    if pct < 0.20 {
        egui::Color32::from_rgb(255, 80, 80) // Critical - red
    } else if pct < 0.35 {
        egui::Color32::from_rgb(255, 180, 80) // Warning - orange
    } else {
        egui::Color32::from_rgb(170, 180, 190) // Normal - gray-white
    }
}

/// Draw EVE-style health arc (semicircular, segmented)
fn draw_eve_health_arc(
    painter: &egui::Painter,
    center: egui::Pos2,
    radius: f32,
    width: f32,
    fill_pct: f32,
    arc_start: f32,
    arc_end: f32,
    fill_color: egui::Color32,
    empty_color: egui::Color32,
    num_segments: u32,
) {
    let segment_gap = 0.02;
    let total_arc = arc_end - arc_start;
    let segment_arc = (total_arc / num_segments as f32) - segment_gap;

    // EVE fills segments from edges toward center
    let filled_segments = (fill_pct * num_segments as f32).ceil() as u32;

    for i in 0..num_segments {
        let angle_start = arc_start + (i as f32) * (total_arc / num_segments as f32);

        // Fill from both edges toward middle
        let half = num_segments / 2;
        let is_filled = if i < half {
            i < filled_segments / 2
        } else {
            (num_segments - i - 1) < filled_segments.div_ceil(2)
        };

        let color = if is_filled || fill_pct >= 1.0 {
            fill_color
        } else {
            empty_color
        };

        draw_arc_segment(painter, center, radius, width, angle_start, segment_arc, color);
    }
}

/// Draw a single arc segment
fn draw_arc_segment(
    painter: &egui::Painter,
    center: egui::Pos2,
    radius: f32,
    width: f32,
    start_angle: f32,
    arc_span: f32,
    color: egui::Color32,
) {
    let steps = 8;
    let inner_r = radius - width / 2.0;
    let outer_r = radius + width / 2.0;

    let mut points = Vec::with_capacity((steps + 1) * 2);

    // Outer arc
    for i in 0..=steps {
        let t = i as f32 / steps as f32;
        let angle = start_angle + arc_span * t;
        points.push(egui::pos2(
            center.x + outer_r * angle.cos(),
            center.y + outer_r * angle.sin(),
        ));
    }

    // Inner arc (reversed)
    for i in (0..=steps).rev() {
        let t = i as f32 / steps as f32;
        let angle = start_angle + arc_span * t;
        points.push(egui::pos2(
            center.x + inner_r * angle.cos(),
            center.y + inner_r * angle.sin(),
        ));
    }

    if points.len() >= 3 {
        painter.add(egui::Shape::convex_polygon(points, color, egui::Stroke::NONE));
    }
}

/// Draw capacitor as concentric rings of dashes (EVE style)
fn draw_capacitor_rings(
    painter: &egui::Painter,
    center: egui::Pos2,
    inner_radius: f32,
    outer_radius: f32,
    cap_pct: f32,
    heat_pct: f32,
    pulse: f32,
) {
    // Number of concentric rings
    let num_rings = 5;
    let ring_spacing = (outer_radius - inner_radius) / num_rings as f32;

    // Capacitor color - golden/orange, shifts red when overheating
    let base_color = if heat_pct > 0.6 {
        // Overheating - shift toward red/orange
        let heat_factor = (heat_pct - 0.6) * 2.5;
        egui::Color32::from_rgb(
            255,
            (180.0 * (1.0 - heat_factor * 0.5)) as u8,
            (100.0 * (1.0 - heat_factor)) as u8,
        )
    } else {
        // Normal - golden orange
        egui::Color32::from_rgb(255, 175, 90)
    };

    let empty_color = egui::Color32::from_rgb(35, 40, 50);

    // Total dashes across all rings
    let total_dashes: u32 = (0..num_rings).map(|r| 8 + r * 4).sum();
    let filled_dashes = (cap_pct * total_dashes as f32) as u32;
    let mut dash_count = 0;

    // Draw each ring from inside out
    for ring in 0..num_rings {
        let ring_radius = inner_radius + 4.0 + ring as f32 * ring_spacing;
        let num_dashes = 8 + ring * 4; // More dashes on outer rings
        let dash_arc = PI * 2.0 / num_dashes as f32;
        let dash_length = dash_arc * 0.6; // 60% of arc is dash, 40% gap
        let dash_width = 3.0 + ring as f32 * 0.5;

        for i in 0..num_dashes {
            let angle = (i as f32 / num_dashes as f32) * PI * 2.0 - PI / 2.0;

            // Determine if this dash is filled (fill from outside in, top first)
            let is_filled = dash_count < filled_dashes;
            dash_count += 1;

            let color = if is_filled {
                // Apply pulse effect to filled dashes
                let brightness = pulse;
                egui::Color32::from_rgb(
                    (base_color.r() as f32 * brightness).min(255.0) as u8,
                    (base_color.g() as f32 * brightness).min(255.0) as u8,
                    (base_color.b() as f32 * brightness).min(255.0) as u8,
                )
            } else {
                empty_color
            };

            draw_capacitor_dash(painter, center, ring_radius, dash_width, angle, dash_length, color);
        }
    }

    // Center glow when capacitor is high
    if cap_pct > 0.3 {
        let glow_alpha = ((cap_pct - 0.3) * 0.5 * 255.0 * pulse) as u8;
        let glow_color = egui::Color32::from_rgba_unmultiplied(
            base_color.r(),
            base_color.g(),
            base_color.b(),
            glow_alpha,
        );
        painter.circle_filled(center, inner_radius * 0.6, glow_color);
    }
}

/// Draw a single capacitor dash (small arc segment)
fn draw_capacitor_dash(
    painter: &egui::Painter,
    center: egui::Pos2,
    radius: f32,
    width: f32,
    start_angle: f32,
    arc_span: f32,
    color: egui::Color32,
) {
    let steps = 4;
    let inner_r = radius - width / 2.0;
    let outer_r = radius + width / 2.0;

    let mut points = Vec::with_capacity((steps + 1) * 2);

    // Outer arc
    for i in 0..=steps {
        let t = i as f32 / steps as f32;
        let angle = start_angle + arc_span * t;
        points.push(egui::pos2(
            center.x + outer_r * angle.cos(),
            center.y + outer_r * angle.sin(),
        ));
    }

    // Inner arc (reversed)
    for i in (0..=steps).rev() {
        let t = i as f32 / steps as f32;
        let angle = start_angle + arc_span * t;
        points.push(egui::pos2(
            center.x + inner_r * angle.cos(),
            center.y + inner_r * angle.sin(),
        ));
    }

    if points.len() >= 3 {
        painter.add(egui::Shape::convex_polygon(points, color, egui::Stroke::NONE));
    }
}

/// Draw overheating status indicators (small orange/red marks)
fn draw_heat_indicators(
    painter: &egui::Painter,
    center: egui::Pos2,
    wheel_radius: f32,
    heat_pct: f32,
) {
    // Position above the capacitor area
    let indicator_radius = wheel_radius - 35.0;
    let num_indicators = 5;
    let filled = (heat_pct * num_indicators as f32).ceil() as u32;

    // Arc from -120 to -60 degrees (top area)
    let start_angle = -PI * 0.7;
    let end_angle = -PI * 0.3;
    let arc_span = end_angle - start_angle;

    for i in 0..num_indicators {
        let angle = start_angle + (i as f32 / (num_indicators - 1) as f32) * arc_span;
        let x = center.x + indicator_radius * angle.cos();
        let y = center.y + indicator_radius * angle.sin();

        let is_active = i < filled;
        let color = if is_active {
            if heat_pct > 0.8 {
                egui::Color32::from_rgb(255, 60, 40) // Critical red
            } else if heat_pct > 0.5 {
                egui::Color32::from_rgb(255, 140, 40) // Warning orange
            } else {
                egui::Color32::from_rgb(255, 200, 80) // Low heat yellow
            }
        } else {
            egui::Color32::from_rgb(40, 45, 55) // Inactive
        };

        // Small rectangular indicator
        let rect = egui::Rect::from_center_size(
            egui::pos2(x, y),
            egui::vec2(4.0, 8.0),
        );
        painter.rect_filled(rect, 1.0, color);
    }
}
