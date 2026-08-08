# Mesolithic Orkney Agent-Based Model

[![CI](https://github.com/SedarOlmez94/Agent_Based_Modelling_Projects/actions/workflows/mesolithic-orkney-abm.yml/badge.svg)](https://github.com/SedarOlmez94/Agent_Based_Modelling_Projects/actions/workflows/mesolithic-orkney-abm.yml)
[![Rust](https://img.shields.io/badge/Rust-2024-000000?logo=rust&logoColor=white)](https://www.rust-lang.org/)
[![egui](https://img.shields.io/badge/GUI-egui%2Feframe-blue)](https://github.com/emilk/egui)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#running-the-model)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../LICENSE)

A Rust re-implementation, with an interactive [egui](https://github.com/emilk/egui)
front-end, of an agent-based model (ABM) of exploratory movement across a
resistance surface of Mesolithic Orkney. The model is a translation of the
original NetLogo `Least_Cost_Exploration_Model` written by Leo Sucharyna Thomas
(2017).

Migrant agents explore a landscape derived from a GIS resistance surface,
preferring higher-resistance terrain while remembering where they have already
been, producing emergent exploratory paths over the topography.

---

## Research context

The code in this repository supports the work in the following paper:

> **Combining agent-based modelling and geographical information systems to
> create a new tool for modelling movement dynamics: A case-study of Mesolithic
> Orkney**
>
> Sucharyna Thomas, L.¹; Wickham-Jones, C. R.²; Heppenstall, A. J.³
>
> 1. School of History, Classics and Archaeology, University of Edinburgh, William Robertson Wing, Old Medical School, Teviot Place, Edinburgh, EH8 9AG.
> 2. Department of Archaeology, University of Aberdeen, Kings College, Aberdeen, AB24 3FX.
> 3. School of Geography, University of Leeds, Leeds, LS2 9JT; Alan Turing Institute, The British Library, London, NW1 2DB.

**Abstract.** The earliest Holocene occupation of Orkney is still poorly
understood, a lack of obvious sites meaning that it has, to date, undergone
inadequate representation in the wider research agenda. This proof-of-concept
study seeks to develop a ground-up modelling environment using advanced
computational techniques in order to place Mesolithic activity within a
realistic landscape setting. Constrained variables pertaining to the base
physical character produce initial insights into site placement and exploratory
movement. This lifts topography and terrain from a passive backdrop to play a
more reactive position within Mesolithic studies, moving away from the static
frameworks of previous analyses. The application of this robust ground-up
approach can be used to test hypotheses and allows the development and layering
of more complex input factors, in order to progress research by addressing
further questions. The approach promotes understanding of post-glacial Orkney
and is widely applicable to other situations around the globe.

---

## Features

- **Interactive GUI** built with `egui`/`eframe`:
  - Dropdown to select a starting position from seven named landing sites.
  - Text input for the number of migrant agents.
  - The resistance surface rendered as a red heatmap (darker = lower resistance;
    NODATA cells drawn dark grey).
  - **Go** / **Stop** buttons driving a continuous, animated tick loop.
  - Migrant trails painted **blue** on top of the resistance surface as they move.
- **Widen search radius** slider (1–20) that lets stuck agents look beyond their
  immediate 8 neighbours for unvisited, accessible terrain.
- **Random multi-agent spawning:** with more than one migrant, each spawns at a
  randomly chosen named starting position and receives a per-agent search radius
  drawn from a normal distribution (mean = slider/2), capped to the slider value.
- **Per-migrant memory:** each agent remembers its own visited patches and avoids
  re-treading them where possible.
- **Auto-stop:** the simulation halts automatically once every agent is stuck
  (no unvisited, accessible patches remain within its search radius).

## How the model works

The landscape is loaded from an ESRI ASCII Grid (`.asc`) resistance surface. On
each tick, every migrant:

1. Looks at its immediate 8 neighbours and selects the unvisited one with the
   highest resistance (ties broken at random).
2. If all neighbours are visited or inaccessible, it widens its search up to its
   `search_radius` for the best unvisited, accessible patch.
3. If still nothing is available, it retreats onto a previously visited neighbour.
4. Records its new position in its personal memory.

This mirrors the greedy, self-avoiding exploratory walk of the original NetLogo
`move` procedure.

## Requirements

- [Rust](https://www.rust-lang.org/tools/install) (2024 edition; stable toolchain).
- On **Linux**, the native GUI/GL system libraries required by `egui`/`eframe`:

  ```bash
  sudo apt-get install -y \
    libgtk-3-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev \
    libxkbcommon-dev libssl-dev libwayland-dev libgl1-mesa-dev
  ```

  macOS and Windows require no extra system packages.

## Running the model

```bash
cd "Archaeology project/rust-revamp/mesolithic-orkey-abm"
cargo run --release
```

> The application loads the resistance surface from `../data/resistance_surface.asc`
> relative to the crate, so run it from the crate directory as shown above.

Then, in the window:

1. Pick a **starting position** from the dropdown.
2. Enter the **number of migrants**.
3. Optionally adjust the **widen search radius** slider.
4. Click **Go** to run the animation, and **Stop** to halt it.

## Development

Build, lint, format, and test:

```bash
cd "Archaeology project/rust-revamp/mesolithic-orkey-abm"
cargo build
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo test
```

The unit tests cover the pure simulation logic (neighbour computation, the
row-flipping resistance/pixel coordinate mapping, greedy destination selection,
the widened search, per-agent radius sampling, and migrant movement) and run
without a display or the on-disk data file.

## Continuous integration

Every push and pull request that touches this project runs the
[CI workflow](../.github/workflows/mesolithic-orkney-abm.yml) on GitHub Actions,
which installs the GUI system dependencies and runs formatting checks, Clippy
(warnings treated as errors), a build, and the test suite.

## Project structure

```text
Archaeology project/
├── Least_Cost_Exploration_Model.nlogo   # Original NetLogo model
├── README.md                            # This file
└── rust-revamp/
    └── mesolithic-orkey-abm/
        ├── Cargo.toml
        ├── data/
        │   └── resistance_surface.asc    # GIS resistance surface (ESRI ASCII Grid)
        └── src/
            └── main.rs                   # Model + egui front-end + tests
```

## Credits

- Original NetLogo model: **Leo Sucharyna Thomas** (2017).
- Rust re-implementation and GUI: **Sedar Olmez**.

## License

Released under the [MIT License](../LICENSE).
