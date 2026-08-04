// Author: Sedar Olmez
// Description: This is the main entry point for the Mesolithic Orkey ABM application. It initializes the application and starts the simulation.
// The application is a translation from Netlogo to Rust.

fn main() {
    // Public variables and constants
    let _resistance_dataset = String::from("resistance_surface.asc");
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
