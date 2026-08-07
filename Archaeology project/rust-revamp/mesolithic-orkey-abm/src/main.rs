
use std::fs;

// Author: Sedar Olmez
// Description: This is the main entry point for the Mesolithic Orkey ABM application. It initializes the application and starts the simulation.
// The application is a translation from Netlogo to Rust.

// gis-tools 1.14.1 only ships a GeoTIFF raster reader, not an ESRI ASCII Grid (.asc)
// reader, so the resistance surface is parsed manually below.
const RESISTANCE_DATASET_PATH: &str = "../data/resistance_surface.asc";

fn main() {
    // Public variables and constants
    let _resistance_dataset = load_resistance_surface(RESISTANCE_DATASET_PATH);
    let _xllcorner_position = 0;
    let _yllcorner_position = 0;
    let _cellsize_position = 0;
    let _nodata_value_position = 0;
    let _memory = 0;
    let mut _unvisited: &[i32] = &[];
    let mut _visited: &[i32] = &[];

    // Environment specific (patch only)
    // patches-own [resistance]
    // [xcor ycor]

    let mut _resistance: &[i32] = &[0, 0];

    // Agent specific (turtle only)
    // breed [migrants migrant]
    // migrants-own
    // [destination secondary]

    let _turtle = Migrant::new(0, 0);

    setup(_resistance);


}

fn setup(_resistance: &[i32]) {
    // Setup the simulation environment and initialize agents
    // This function would typically read the resistance dataset, set up the grid, and create initial agents

    clear_all();
    reset_ticks();

    println!("Dataset Loaded");
    let resistance_dataset = setup_resistance_surface(RESISTANCE_DATASET_PATH);
    println!("Dataset Displayed");
    display_resistance_in_patches(&resistance_dataset, _resistance);
    setup_migrants();
    println!("Migrants Ready");

}

struct Migrant {
    destination: i32,
    secondary: i32,
}

impl Migrant {
    fn new(destination: i32, secondary: i32) -> Self {
        Migrant {
            destination,
            secondary,
        }
    }
}

fn clear_all() {
    // Clear all agents and reset the environment
    // This function would typically remove all agents from the simulation and reset any relevant state
}

fn reset_ticks() {
    // Reset the simulation ticks
    // This function would typically reset the simulation clock or step counter
}

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
}

fn load_resistance_surface(path: &str) -> ResistanceSurface {
    let contents = fs::read_to_string(path)
        .unwrap_or_else(|e| panic!("Failed to read resistance dataset '{path}': {e}"));
    let mut lines = contents.lines();

    let mut header_value = || -> String {
        let line = lines.next().expect("Missing header line in resistance surface file");
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

    ResistanceSurface { ncols, nrows, xllcorner, yllcorner, cellsize, nodata_value, data }
}

fn setup_resistance_surface(path: &str) -> ResistanceSurface {
    // Read the resistance dataset and initialize the environment grid
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

fn setup_migrants() {
    // Setup the initial migrant agents
    // This function would typically create the initial set of migrant agents
}

fn display_resistance() {
    // Display the resistance surface
    // This function would typically render the resistance surface on the simulation interface

    ////   gis:paint resistance-dataset 0
}

fn display_resistance_in_patches(resistance_dataset: &ResistanceSurface, _resistance: &[i32]) {
    // Display the resistance surface in patches
    // This function would typically render the resistance surface on the simulation interface using patches

    // to display-resistance-in-patches
    //   ; This is the preferred way of copying values from a raster dataset
    //   ; into a patch variable in one step, using gis:apply-raster.

    //   gis:apply-raster resistance-dataset resistance
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

    //   ; Now, just to make sure it worked, we'll color each patch by its resistance value.
    //   ; set min as 0, otherwise will gradiate from the 'NoData value of '-9999'.
    let min_resistance = 0.0;
    let max_resistance = resistance_dataset.data.len() as f64;

    if (_resistance[0] == 0) || (_resistance[0] >= 0) {
        
        let pcolour = scale_red(
            _resistance,
            min_resistance,
            max_resistance,
        );

        println!("Patch color: {pcolour}");
    }

    println!("start");
    let mut world = World { min_pxcor: 0, max_pxcor: 0, min_pycor: 0, max_pycor: 0 };
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
    // Scale the resistance value to a color in the red spectrum
    // This function would typically map the resistance value to a color for visualization

    let normalized = (value[0] as f64 - min) / (max - min);
    let red_intensity = (normalized * 255.0).clamp(0.0, 255.0) as u8;
    format!("#{:02X}0000", red_intensity)
}
