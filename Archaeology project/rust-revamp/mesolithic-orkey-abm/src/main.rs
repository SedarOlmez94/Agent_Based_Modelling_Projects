/*
Author: Sedar Olmez
Description: This is the main entry point for the Mesolithic Orkey ABM application. It initialises the application and starts the simulation.
The application is a translation from Netlogo to Rust.
*/


fn main() {


    /*
    Public variables and constants are defined here. These variables are used throughout the application and can be accessed from other modules.
    globals[
        resistance-dataset ; contains the movement speed values for each patch

            xllcorner_position
            yllcorner_position
            cellsize_position
            NODATA_value_position
            header_items
            memory
            unvisited
            visited
    ]
     */

    // Public variables and constants
    let _resistance_dataset:String = String::from("resistance_surface.asc");
    let _xllcorner_position:i32 = 0;
    let _yllcorner_position:i32 = 0;
    let _cellsize_position:i32 = 0;
    let _nodata_value_position:i32 = 0;
    let _memory:i32 = 0;
    let mut _unvisited:&[i32] = &[0];
    let mut _visited:&[i32] = &[0];

    // Environment specific (patch only)
    // patches-own [resistance]
    // [xcor ycor]

    let mut _resistance:&[i32] = &[0, 0];

    // Agent specific (turtle only)
    /*
    breed [migrants migrant]
      migrants-own
      [destination secondary]
     */
    
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
