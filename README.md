# MAGSEAL

MAGSEAL is an autonomous spacecraft leak-repair concept developed for UB Hacking. The proposed system detects a pressure drop, positions an electromagnetic repair head, gathers magnetic repair material at the puncture, and uses UV light to cure the seal.

This repository contains MATLAB studies of pressure loss, magnetic guidance, material delivery, and sealing. The current design baseline is a 6 mm puncture. Earlier simulations explore different repair mechanisms.

## Run the simulations

Open the folder containing the relevant scripts in MATLAB and run one of the following.

| Study | Folder | Command |
|---|---|---|
| Pressure loss and detection | `matlab` | `run_magseal_step1` |
| Guided module motion | `matlab` | `run_magseal_hour3` |
| Membrane retention and pressure feedback | `matlab` | `run_magseal_hour4` |
| Particle sealing and coil guidance | Repository root | `run_magseal_two_tests` |
| Autonomous plug feasibility | Repository root | `run_magseal_autonomous_plug` |
| Positioned coil | Repository root | `run_magseal_positioned_coil` |

Keep each study's supporting files together. The Hour 3 workflow and optional Simulink models require Simulink.

## Development status

The simulations use assumed material and hardware properties alongside published research. Pressure sealing, robotic deployment, and UV curing still require experimental validation. Each study's parameters and documentation describe its assumptions.

See [sources and assumptions](SOURCES_AND_ASSUMPTIONS.md) and the [Hour 4 model notes](docs/README_START_HERE.md) for technical details.
