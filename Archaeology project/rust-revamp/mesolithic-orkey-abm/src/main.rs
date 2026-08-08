// Author: Sedar Olmez
// Description: This is the main entry point for the Mesolithic Orkey ABM application. It initializes the application and starts the simulation.
// The application is a translation from Netlogo to Rust. The original NetLogo code was written by Leo Sucharyna Thomas in 2017

// Several functions are 1:1 translations of NetLogo procedures kept for reference
// (e.g. the CLI `setup` harness and the console `display_*`/`export` helpers) even
// though the egui front-end doesn't call them, so dead code is allowed crate-wide.
#![allow(dead_code)]

use eframe::egui;
use rand::prelude::IndexedRandom;
use rand::{Rng, RngExt};
use std::fs;

// gis-tools 1.14.1 only ships a GeoTIFF raster reader, not an ESRI ASCII Grid (.asc)
// reader, so the resistance surface is parsed manually below.
const RESISTANCE_DATASET_PATH: &str = "../data/resistance_surface.asc";

fn main() -> eframe::Result {
    eframe::run_native(
        "Mesolithic Orkney ABM",
        eframe::NativeOptions::default(),
        Box::new(|cc| Ok(Box::new(App::new(cc)))),
    )
}

fn setup(_resistance: &[i32], _number_of_migrants: i32, starting_position: &str) {
    clear_all();
    reset_ticks();

    println!("Dataset Loaded");
    let resistance_dataset = setup_resistance_surface(RESISTANCE_DATASET_PATH);
    println!("Dataset Displayed");
    display_resistance_in_patches(&resistance_dataset, _resistance);
    let (_migrants, _visited) = setup_migrants(
        _number_of_migrants,
        starting_position,
        &resistance_dataset,
        1,
    );
    println!("Migrants Ready");
}

struct Migrant {
    x: i32,
    y: i32,
    destination: Option<(i32, i32)>,
    secondary: i32,
    memory: Vec<(i32, i32)>,
    search_radius: i32,
}

impl Migrant {
    fn new(secondary: i32) -> Self {
        Migrant {
            x: 0,
            y: 0,
            destination: None,
            secondary,
            memory: Vec::new(),
            search_radius: 1,
        }
    }

    fn setxy(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }
}

fn clear_all() {}

fn reset_ticks() {}

/// ESRI ASCII Grid (.asc) raster: 6-line header followed by row-major cell values.
struct ResistanceSurface {
    ncols: usize,
    nrows: usize,
    xllcorner: f64,
    yllcorner: f64,
    cellsize: f64,
    nodata_value: f64,
    data: Vec<f64>,
}

impl ResistanceSurface {
    fn value(&self, row: usize, col: usize) -> f64 {
        self.data[row * self.ncols + col]
    }

    /// Resistance at a NetLogo patch coordinate, or `None` if out of bounds/NODATA.
    /// Patch pycor grows northward while raster rows grow southward, so the row is flipped.
    fn resistance_at_patch(&self, pxcor: i32, pycor: i32) -> Option<f64> {
        if pxcor < 0 || pycor < 0 {
            return None;
        }
        let col = pxcor as usize;
        let row = self.nrows.checked_sub(1)?.checked_sub(pycor as usize)?;
        if col >= self.ncols {
            return None;
        }
        let v = self.value(row, col);
        (v != self.nodata_value).then_some(v)
    }
}

fn load_resistance_surface(path: &str) -> ResistanceSurface {
    let contents = fs::read_to_string(path)
        .unwrap_or_else(|e| panic!("Failed to read resistance dataset '{path}': {e}"));
    let mut lines = contents.lines();

    let mut header_value = || -> String {
        let line = lines
            .next()
            .expect("Missing header line in resistance surface file");
        line.split_whitespace()
            .nth(1)
            .expect("Malformed header line in resistance surface file")
            .to_string()
    };

    let ncols: usize = header_value().parse().expect("Invalid ncols");
    let nrows: usize = header_value().parse().expect("Invalid nrows");
    let xllcorner: f64 = header_value().parse().expect("Invalid xllcorner");
    let yllcorner: f64 = header_value().parse().expect("Invalid yllcorner");
    let cellsize: f64 = header_value().parse().expect("Invalid cellsize");
    let nodata_value: f64 = header_value().parse().expect("Invalid NODATA_value");

    let mut data = Vec::with_capacity(ncols * nrows);
    for line in lines {
        for token in line.split_whitespace() {
            data.push(token.parse::<f64>().expect("Invalid resistance value"));
        }
    }

    ResistanceSurface {
        ncols,
        nrows,
        xllcorner,
        yllcorner,
        cellsize,
        nodata_value,
        data,
    }
}

fn setup_resistance_surface(path: &str) -> ResistanceSurface {
    load_resistance_surface(path)
}

/// Mirrors NetLogo's implicit world state: the patch coordinate bounds set by `resize-world`.
struct World {
    min_pxcor: i32,
    max_pxcor: i32,
    min_pycor: i32,
    max_pycor: i32,
}

impl World {
    /// Equivalent to NetLogo's `resize-world min-pxcor max-pxcor min-pycor max-pycor`.
    /// In NetLogo this also wipes all patches/turtles; here it just redefines the bounds
    /// since patches aren't allocated until something asks for them.
    fn resize_world(&mut self, min_pxcor: i32, max_pxcor: i32, min_pycor: i32, max_pycor: i32) {
        self.min_pxcor = min_pxcor;
        self.max_pxcor = max_pxcor;
        self.min_pycor = min_pycor;
        self.max_pycor = max_pycor;
    }

    fn width(&self) -> i32 {
        self.max_pxcor - self.min_pxcor + 1
    }

    fn height(&self) -> i32 {
        self.max_pycor - self.min_pycor + 1
    }
}

/// Equivalent to NetLogo's `neighbors`: the up-to-8 surrounding patches, clipped to the world.
fn neighbors(pxcor: i32, pycor: i32, max_pxcor: i32, max_pycor: i32) -> Vec<(i32, i32)> {
    patches_within_radius(pxcor, pycor, 1, max_pxcor, max_pycor)
}

/// All patches within Chebyshev distance `radius` (a `radius`=1 square is the same as `neighbors`).
fn patches_within_radius(
    pxcor: i32,
    pycor: i32,
    radius: i32,
    max_pxcor: i32,
    max_pycor: i32,
) -> Vec<(i32, i32)> {
    let mut result = Vec::new();
    for dx in -radius..=radius {
        for dy in -radius..=radius {
            if dx == 0 && dy == 0 {
                continue;
            }
            let (nx, ny) = (pxcor + dx, pycor + dy);
            if (0..=max_pxcor).contains(&nx) && (0..=max_pycor).contains(&ny) {
                result.push((nx, ny));
            }
        }
    }
    result
}

/// Equivalent to NetLogo's `max-one-of neighbors [resistance]`.
fn max_one_of_neighbors_by_resistance(
    pxcor: i32,
    pycor: i32,
    resistance_dataset: &ResistanceSurface,
) -> Option<(i32, i32)> {
    let max_pxcor = resistance_dataset.ncols as i32 - 1;
    let max_pycor = resistance_dataset.nrows as i32 - 1;
    neighbors(pxcor, pycor, max_pxcor, max_pycor)
        .into_iter()
        .filter_map(|(nx, ny)| {
            resistance_dataset
                .resistance_at_patch(nx, ny)
                .map(|r| (r, (nx, ny)))
        })
        .max_by(|(r1, _), (r2, _)| r1.partial_cmp(r2).unwrap())
        .map(|(_, coord)| coord)
}

/// Looks up the fixed (x, y) coordinates for one of the named `STARTING_POSITIONS`.
fn resolve_starting_position(starting_position: &str) -> (i32, i32) {
    match starting_position {
        "1. (203)(34)" => (203, 34),
        "2. (192)(48)" => (192, 48),
        "3. (186)(27)" => (186, 27),
        "4. (174)(21)" => (174, 21),
        "5. (161)(12)" => (161, 12),
        "6. (144)(7)" => (144, 7),
        "7. (154)(0)" => (154, 0),
        _ => {
            println!("error in choice of map to load!");
            (0, 0)
        }
    }
}

/// Samples a per-migrant search radius from a normal distribution capped to `[1, max_radius]`.
fn sample_normal_radius(max_radius: i32, rng: &mut impl Rng) -> i32 {
    if max_radius <= 1 {
        return max_radius.max(1);
    }
    let mean = max_radius as f64 / 2.0;
    let std_dev = max_radius as f64 / 4.0;
    let u1: f64 = rng.random_range(f64::EPSILON..1.0);
    let u2: f64 = rng.random_range(0.0..1.0);
    let z = (-2.0_f64 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos();
    (mean + std_dev * z).round().clamp(1.0, max_radius as f64) as i32
}

fn setup_migrants(
    number_of_migrants: i32,
    starting_position: &str,
    resistance_dataset: &ResistanceSurface,
    search_radius_max: i32,
) -> (Vec<Migrant>, Vec<(i32, i32)>) {
    let mut migrants: Vec<Migrant> = (0..number_of_migrants).map(|_| Migrant::new(0)).collect();
    let mut rng = rand::rng();
    let mut visited = Vec::new();

    for migrant in &mut migrants {
        // With more than one migrant, each spawns at a randomly chosen named starting position.
        let (x, y) = if number_of_migrants > 1 {
            let name = STARTING_POSITIONS
                .choose(&mut rng)
                .copied()
                .unwrap_or(starting_position);
            resolve_starting_position(name)
        } else {
            resolve_starting_position(starting_position)
        };
        migrant.setxy(x, y);
        migrant.memory = vec![(x, y)];
        migrant.search_radius = if number_of_migrants > 1 {
            sample_normal_radius(search_radius_max, &mut rng)
        } else {
            search_radius_max
        };
        visited.push((x, y));
    }

    for migrant in &mut migrants {
        migrant.destination =
            max_one_of_neighbors_by_resistance(migrant.x, migrant.y, resistance_dataset);
        println!("{:?}", migrant.destination);
    }
    println!("Destination Set");

    (migrants, visited)
}

fn display_resistance() {
    // NetLogo: gis:paint resistance-dataset 0
}

fn display_resistance_in_patches(resistance_dataset: &ResistanceSurface, _resistance: &[i32]) {
    let valid_values = resistance_dataset
        .data
        .iter()
        .copied()
        .filter(|&v| v != resistance_dataset.nodata_value);
    let min_resistance = valid_values.clone().fold(f64::INFINITY, f64::min);
    let max_resistance = valid_values.fold(f64::NEG_INFINITY, f64::max);
    println!(
        "Resistance grid: {}x{} cells, range {min_resistance} - {max_resistance}",
        resistance_dataset.ncols, resistance_dataset.nrows
    );

    // min stays 0 so colors don't gradiate from the NODATA_value
    let min_resistance = 0.0;
    let max_resistance = resistance_dataset.data.len() as f64;

    if (_resistance[0] == 0) || (_resistance[0] >= 0) {
        let pcolour = scale_red(_resistance, min_resistance, max_resistance);
        println!("Patch color: {pcolour}");
    }

    println!("start");
    let mut world = World {
        min_pxcor: 0,
        max_pxcor: 0,
        min_pycor: 0,
        max_pycor: 0,
    };
    world.resize_world(
        0,
        resistance_dataset.ncols as i32 - 1,
        0,
        resistance_dataset.nrows as i32 - 1,
    );
    println!(
        "World resized to {}x{} patches (pxcor 0..={}, pycor 0..={})",
        world.width(),
        world.height(),
        world.max_pxcor,
        world.max_pycor
    );
    println!("finish");
}

fn scale_red(value: &[i32], min: f64, max: f64) -> String {
    let normalized = (value[0] as f64 - min) / (max - min);
    let red_intensity = (normalized * 255.0).clamp(0.0, 255.0) as u8;
    format!("#{:02X}0000", red_intensity)
}

fn move_migrants(migrants: &mut [Migrant], resistance_dataset: &ResistanceSurface) {
    let max_pxcor = resistance_dataset.ncols as i32 - 1;
    let max_pycor = resistance_dataset.nrows as i32 - 1;
    let mut rng = rand::rng();

    for migrant in migrants.iter_mut() {
        let all_neighbors = neighbors(migrant.x, migrant.y, max_pxcor, max_pycor);
        let unvisited: Vec<(i32, i32)> = all_neighbors
            .iter()
            .copied()
            .filter(|coord| !migrant.memory.contains(coord))
            .collect();

        // `set destination one-of unvisited with-max [resistance]`
        let best_resistance = unvisited
            .iter()
            .filter_map(|&(nx, ny)| resistance_dataset.resistance_at_patch(nx, ny))
            .fold(f64::NEG_INFINITY, f64::max);
        let candidates: Vec<(i32, i32)> = unvisited
            .iter()
            .copied()
            .filter(|&(nx, ny)| {
                resistance_dataset.resistance_at_patch(nx, ny) == Some(best_resistance)
            })
            .collect();
        let destination = candidates.choose(&mut rng).copied().or_else(|| {
            // Widen the search: if the immediate neighbors are all visited/inaccessible,
            // look further afield (up to the migrant's search radius) for an unvisited patch.
            let wide_unvisited: Vec<(i32, i32)> = patches_within_radius(
                migrant.x,
                migrant.y,
                migrant.search_radius,
                max_pxcor,
                max_pycor,
            )
            .into_iter()
            .filter(|coord| !migrant.memory.contains(coord))
            .collect();
            let best_wide = wide_unvisited
                .iter()
                .filter_map(|&(nx, ny)| resistance_dataset.resistance_at_patch(nx, ny))
                .fold(f64::NEG_INFINITY, f64::max);
            wide_unvisited
                .iter()
                .copied()
                .filter(|&(nx, ny)| {
                    resistance_dataset.resistance_at_patch(nx, ny) == Some(best_wide)
                })
                .collect::<Vec<_>>()
                .choose(&mut rng)
                .copied()
        });
        migrant.destination = destination;

        match destination {
            // `member? destination neighbors [move-to destination]`
            Some((nx, ny)) => migrant.setxy(nx, ny),
            // `destination = NOBODY [move-to one-of neighbors with [member? self [memory] of myself]]`
            None => {
                let visited_neighbors: Vec<(i32, i32)> = all_neighbors
                    .iter()
                    .copied()
                    .filter(|coord| migrant.memory.contains(coord))
                    .collect();
                match visited_neighbors.choose(&mut rng) {
                    Some(&(nx, ny)) => migrant.setxy(nx, ny),
                    None => println!("Help!"),
                }
            }
        }

        migrant.memory.push((migrant.x, migrant.y));
    }
}

fn tick() {}

fn go(migrants: &mut [Migrant], resistance_dataset: &ResistanceSurface) {
    move_migrants(migrants, resistance_dataset);
    tick();
}

fn patches_white() {
    // NetLogo: ask patches [set pcolor white] — purely visual; no patch rendering exists here.
}

fn export(migrants: &[Migrant]) {
    let mut csv = String::from("migrant_id,step,x,y\n");
    for (id, migrant) in migrants.iter().enumerate() {
        for (step, &(x, y)) in migrant.memory.iter().enumerate() {
            csv.push_str(&format!("{id},{step},{x},{y}\n"));
        }
    }
    fs::write("movement.csv", csv)
        .unwrap_or_else(|e| panic!("Failed to export movement data: {e}"));
}

const TICK_INTERVAL: std::time::Duration = std::time::Duration::from_millis(150);

const STARTING_POSITIONS: [&str; 7] = [
    "1. (203)(34)",
    "2. (192)(48)",
    "3. (186)(27)",
    "4. (174)(21)",
    "5. (161)(12)",
    "6. (144)(7)",
    "7. (154)(0)",
];

/// Same north/south row flip as `ResistanceSurface::resistance_at_patch`, for painting pixels.
fn patch_to_pixel(pxcor: i32, pycor: i32, ncols: usize, nrows: usize) -> Option<(usize, usize)> {
    if pxcor < 0 || pycor < 0 {
        return None;
    }
    let col = pxcor as usize;
    let row = nrows.checked_sub(1)?.checked_sub(pycor as usize)?;
    (col < ncols && row < nrows).then_some((col, row))
}

fn resistance_color(value: f64, min: f64, max: f64) -> egui::Color32 {
    let normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    egui::Color32::from_rgb((normalized * 255.0) as u8, 0, 0)
}

/// Renders the resistance surface as a red heatmap; NODATA cells are drawn dark gray.
fn build_heatmap_image(resistance_dataset: &ResistanceSurface) -> egui::ColorImage {
    let valid = resistance_dataset
        .data
        .iter()
        .copied()
        .filter(|&v| v != resistance_dataset.nodata_value);
    let min = valid.clone().fold(f64::INFINITY, f64::min);
    let max = valid.fold(f64::NEG_INFINITY, f64::max);

    let ncols = resistance_dataset.ncols;
    let nrows = resistance_dataset.nrows;
    let mut image =
        egui::ColorImage::new([ncols, nrows], vec![egui::Color32::BLACK; ncols * nrows]);
    for (pixel, &value) in image.pixels.iter_mut().zip(&resistance_dataset.data) {
        *pixel = if value == resistance_dataset.nodata_value {
            egui::Color32::from_gray(20)
        } else {
            resistance_color(value, min, max)
        };
    }
    image
}

/// UI state driving the simulation: dropdown/text-input parameters, the running migrants,
/// and the heatmap texture (resistance in red, migrant trails painted blue on top).
struct App {
    resistance_dataset: ResistanceSurface,
    heatmap_image: egui::ColorImage,
    texture: egui::TextureHandle,
    migrants: Vec<Migrant>,
    starting_position: String,
    number_of_migrants_input: String,
    search_radius: i32,
    running: bool,
    tick_count: u64,
    last_tick: std::time::Instant,
}

impl App {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let resistance_dataset = setup_resistance_surface(RESISTANCE_DATASET_PATH);
        let heatmap_image = build_heatmap_image(&resistance_dataset);
        let texture = cc.egui_ctx.load_texture(
            "resistance-heatmap",
            heatmap_image.clone(),
            egui::TextureOptions::NEAREST,
        );

        App {
            resistance_dataset,
            heatmap_image,
            texture,
            migrants: Vec::new(),
            starting_position: STARTING_POSITIONS[0].to_string(),
            number_of_migrants_input: "1".to_string(),
            search_radius: 1,
            running: false,
            tick_count: 0,
            last_tick: std::time::Instant::now(),
        }
    }

    /// `setup` + starting the animation loop: rebuilds migrants from the current UI parameters.
    fn start(&mut self) {
        let number_of_migrants = self
            .number_of_migrants_input
            .trim()
            .parse::<i32>()
            .unwrap_or(0)
            .max(0);
        self.heatmap_image = build_heatmap_image(&self.resistance_dataset);
        let (migrants, _visited) = setup_migrants(
            number_of_migrants,
            &self.starting_position,
            &self.resistance_dataset,
            self.search_radius,
        );
        self.migrants = migrants;
        self.tick_count = 0;
        self.paint_migrant_trails();
        self.sync_texture();
        self.running = number_of_migrants > 0;
        self.last_tick = std::time::Instant::now();
    }

    /// One `go` tick, auto-stopping once every migrant is stuck (no unvisited or visited neighbors left).
    fn step(&mut self) {
        go(&mut self.migrants, &self.resistance_dataset);
        self.tick_count += 1;
        self.paint_migrant_trails();
        self.sync_texture();

        let max_pxcor = self.resistance_dataset.ncols as i32 - 1;
        let max_pycor = self.resistance_dataset.nrows as i32 - 1;
        let all_stuck = self.migrants.iter().all(|migrant| {
            patches_within_radius(
                migrant.x,
                migrant.y,
                migrant.search_radius,
                max_pxcor,
                max_pycor,
            )
            .iter()
            .all(|&(nx, ny)| {
                migrant.memory.contains(&(nx, ny))
                    || self
                        .resistance_dataset
                        .resistance_at_patch(nx, ny)
                        .is_none()
            })
        });
        if all_stuck {
            self.running = false;
        }
    }

    fn paint_migrant_trails(&mut self) {
        let ncols = self.resistance_dataset.ncols;
        let nrows = self.resistance_dataset.nrows;
        for migrant in &self.migrants {
            if let Some(&(x, y)) = migrant.memory.last()
                && let Some((col, row)) = patch_to_pixel(x, y, ncols, nrows)
            {
                self.heatmap_image.pixels[row * ncols + col] = egui::Color32::BLUE;
            }
        }
    }

    fn sync_texture(&mut self) {
        self.texture
            .set(self.heatmap_image.clone(), egui::TextureOptions::NEAREST);
    }
}

impl eframe::App for App {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        egui::Panel::left("controls").show(ui, |ui| {
            ui.heading("Simulation Controls");
            ui.add_space(8.0);

            egui::ComboBox::from_label("Starting position")
                .selected_text(self.starting_position.clone())
                .show_ui(ui, |ui| {
                    for position in STARTING_POSITIONS {
                        ui.selectable_value(
                            &mut self.starting_position,
                            position.to_string(),
                            position,
                        );
                    }
                });

            ui.horizontal(|ui| {
                ui.label("Number of migrants:");
                ui.text_edit_singleline(&mut self.number_of_migrants_input);
            });
            if self.number_of_migrants_input.trim().parse::<i32>().is_err() {
                ui.colored_label(egui::Color32::RED, "Enter a whole number");
            }

            ui.add_space(8.0);
            ui.add(egui::Slider::new(&mut self.search_radius, 1..=20).text("Widen search radius"));

            ui.add_space(8.0);
            ui.horizontal(|ui| {
                if ui.button("Go").clicked() {
                    self.start();
                }
                if ui.button("Stop").clicked() {
                    self.running = false;
                }
            });

            ui.add_space(8.0);
            ui.label(format!("Tick: {}", self.tick_count));
            ui.label(if self.running {
                "Status: running"
            } else {
                "Status: stopped"
            });
        });

        egui::CentralPanel::default().show(ui, |ui| {
            let available = ui.available_size();
            let side = available.x.min(available.y);
            let (rect, _response) =
                ui.allocate_exact_size(egui::vec2(side, side), egui::Sense::hover());
            ui.painter().image(
                self.texture.id(),
                rect,
                egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0)),
                egui::Color32::WHITE,
            );
        });

        if self.running {
            let now = std::time::Instant::now();
            if now.duration_since(self.last_tick) >= TICK_INTERVAL {
                self.step();
                self.last_tick = now;
            }
            ui.ctx().request_repaint_after(TICK_INTERVAL);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Builds a small in-memory resistance surface for deterministic tests,
    /// avoiding any dependency on the on-disk `.asc` file or the working directory.
    fn test_surface() -> ResistanceSurface {
        // 3x3 grid; each cell's resistance equals its row-major index.
        ResistanceSurface {
            ncols: 3,
            nrows: 3,
            xllcorner: 0.0,
            yllcorner: 0.0,
            cellsize: 1.0,
            nodata_value: -9999.0,
            data: vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
        }
    }

    #[test]
    fn neighbors_are_clipped_to_world_bounds() {
        // Corner patch has only 3 in-bounds neighbors.
        let corner = neighbors(0, 0, 2, 2);
        assert_eq!(corner.len(), 3);
        // Center patch has all 8 neighbors.
        let center = neighbors(1, 1, 2, 2);
        assert_eq!(center.len(), 8);
    }

    #[test]
    fn neighbors_matches_radius_one() {
        let n = neighbors(1, 1, 2, 2);
        let r = patches_within_radius(1, 1, 1, 2, 2);
        assert_eq!(n, r);
    }

    #[test]
    fn patches_within_radius_widens_search() {
        // Radius 2 on a 5x5 world from the center yields all 24 surrounding patches.
        let patches = patches_within_radius(2, 2, 2, 4, 4);
        assert_eq!(patches.len(), 24);
        assert!(!patches.contains(&(2, 2)), "must exclude the center patch");
    }

    #[test]
    fn resistance_at_patch_flips_rows_and_handles_bounds() {
        let surface = test_surface();
        // pycor grows north; pycor=2 maps to raster row 0 (top).
        assert_eq!(surface.resistance_at_patch(0, 2), Some(0.0));
        // pycor=0 maps to the bottom raster row.
        assert_eq!(surface.resistance_at_patch(0, 0), Some(6.0));
        // Out of bounds returns None.
        assert_eq!(surface.resistance_at_patch(-1, 0), None);
        assert_eq!(surface.resistance_at_patch(3, 0), None);
    }

    #[test]
    fn resistance_at_patch_treats_nodata_as_none() {
        let mut surface = test_surface();
        surface.data[0] = surface.nodata_value;
        assert_eq!(surface.resistance_at_patch(0, 2), None);
    }

    #[test]
    fn patch_to_pixel_round_trips_within_bounds() {
        assert_eq!(patch_to_pixel(0, 2, 3, 3), Some((0, 0)));
        assert_eq!(patch_to_pixel(2, 0, 3, 3), Some((2, 2)));
        assert_eq!(patch_to_pixel(-1, 0, 3, 3), None);
    }

    #[test]
    fn max_one_of_neighbors_picks_highest_resistance() {
        let surface = test_surface();
        // From patch (0,0) the neighbors are (1,0),(0,1),(1,1); highest resistance wins.
        let best = max_one_of_neighbors_by_resistance(0, 0, &surface);
        assert!(best.is_some());
        let (bx, by) = best.unwrap();
        let best_r = surface.resistance_at_patch(bx, by).unwrap();
        for (nx, ny) in neighbors(0, 0, 2, 2) {
            if let Some(r) = surface.resistance_at_patch(nx, ny) {
                assert!(best_r >= r);
            }
        }
    }

    #[test]
    fn resolve_starting_position_maps_named_positions() {
        assert_eq!(resolve_starting_position("1. (203)(34)"), (203, 34));
        assert_eq!(resolve_starting_position("7. (154)(0)"), (154, 0));
    }

    #[test]
    fn sample_normal_radius_stays_within_bounds() {
        let mut rng = rand::rng();
        assert_eq!(sample_normal_radius(1, &mut rng), 1);
        for _ in 0..1000 {
            let r = sample_normal_radius(20, &mut rng);
            assert!((1..=20).contains(&r), "radius {r} out of range");
        }
    }

    #[test]
    fn move_migrants_records_a_new_memory_entry() {
        let surface = test_surface();
        let mut migrants = vec![Migrant::new(0)];
        migrants[0].setxy(1, 1);
        migrants[0].memory = vec![(1, 1)];
        let before = migrants[0].memory.len();
        move_migrants(&mut migrants, &surface);
        assert_eq!(migrants[0].memory.len(), before + 1);
        // The migrant must have moved to one of its neighbors.
        let (x, y) = (migrants[0].x, migrants[0].y);
        assert!(neighbors(1, 1, 2, 2).contains(&(x, y)));
    }

    #[test]
    fn move_migrants_avoids_revisiting_when_possible() {
        let surface = test_surface();
        let mut migrants = vec![Migrant::new(0)];
        migrants[0].setxy(0, 0);
        migrants[0].memory = vec![(0, 0)];
        move_migrants(&mut migrants, &surface);
        // After one move, it should have stepped onto a previously unvisited neighbor.
        let (x, y) = (migrants[0].x, migrants[0].y);
        assert_ne!((x, y), (0, 0));
    }
}
