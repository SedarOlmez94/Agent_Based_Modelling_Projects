use std::fs;
use rand::prelude::IndexedRandom;

// Author: Sedar Olmez
// Description: This is the main entry point for the Mesolithic Orkey ABM application. It initializes the application and starts the simulation.
// The application is a translation from Netlogo to Rust.

// gis-tools 1.14.1 only ships a GeoTIFF raster reader, not an ESRI ASCII Grid (.asc)
// reader, so the resistance surface is parsed manually below.
const RESISTANCE_DATASET_PATH: &str = "../data/resistance_surface.asc";

fn main() {
    let _resistance_dataset = load_resistance_surface(RESISTANCE_DATASET_PATH);
    let _xllcorner_position = 0;
    let _yllcorner_position = 0;
    let _cellsize_position = 0;
    let _nodata_value_position = 0;
    let _memory = 0;
    let mut _unvisited: &[i32] = &[];
    let mut _visited: &[i32] = &[];

    let mut _resistance: &[i32] = &[0, 0];

    let _turtle = Migrant::new(0);
    let _number_of_migrants = 0;
    let starting_position = "1. (203)(34)";

    setup(_resistance, _number_of_migrants, starting_position);
}

fn setup(_resistance: &[i32], _number_of_migrants: i32, starting_position: &str) {
    clear_all();
    reset_ticks();

    println!("Dataset Loaded");
    let resistance_dataset = setup_resistance_surface(RESISTANCE_DATASET_PATH);
    println!("Dataset Displayed");
    display_resistance_in_patches(&resistance_dataset, _resistance);
    let (_migrants, _visited) =
        setup_migrants(_number_of_migrants, starting_position, &resistance_dataset);
    println!("Migrants Ready");
}

struct Migrant {
    x: i32,
    y: i32,
    destination: Option<(i32, i32)>,
    secondary: i32,
    memory: Vec<(i32, i32)>,
}

impl Migrant {
    fn new(secondary: i32) -> Self {
        Migrant {
            x: 0,
            y: 0,
            destination: None,
            secondary,
            memory: Vec::new(),
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
    let mut result = Vec::with_capacity(8);
    for dx in -1..=1 {
        for dy in -1..=1 {
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

fn setup_migrants(
    number_of_migrants: i32,
    starting_position: &str,
    resistance_dataset: &ResistanceSurface,
) -> (Vec<Migrant>, Vec<(i32, i32)>) {
    let mut migrants: Vec<Migrant> = (0..number_of_migrants).map(|_| Migrant::new(0)).collect();

    let (x, y) = match starting_position {
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
    };

    for migrant in &mut migrants {
        migrant.setxy(x, y);
        migrant.memory = vec![(x, y)];
    }

    // `visited` stays a global (unlike memory, it's never read again after setup in the original model).
    let visited = vec![(x, y)];

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
        let destination: Vec<(i32, i32)> = unvisited
            .iter()
            .copied()
            .filter(|&(nx, ny)| resistance_dataset.resistance_at_patch(nx, ny) == Some(best_resistance))
            .collect();
        let destination = destination.choose(&mut rng).copied();
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
