# MAGSEAL membrane model

This earlier study couples pressure loss, detection, guided module motion and an assumed retaining membrane.

## Run

Open the `matlab` folder in MATLAB.

```matlab
run_magseal_hour4
verify_magseal_hour4
```

For the optional Simulink comparison, run `run_magseal_hour4_simulink`. It replays MATLAB's contact timeline and calculates pressure feedback.

## Model

A puncture causes air loss. A 100 Pa pressure drop activates the coil. Twelve guided modules move toward the opening. Once all arrive, the model checks seating time, cover overlap and retention capacity before reducing the effective leak area.

| Input | Assumed value |
|---|---|
| Hole diameter | 6 mm |
| Initial cabin pressure | 101,325 Pa |
| Cabin volume | 20 m³ |
| Module mass | 3 g each |
| Magnetic moment | 0.013116 A m² per module |
| Reference field gradient | 0.50 T/m at 18 mm |
| Static friction | 2 mN |
| Cover diameter | 12 mm |
| Minimum radial overlap | 2 mm |
| Seating delay | 0.30 s |
| Latch capacity | 10 N |
| Pressure-load multiplier | 3 |
| Nominal residual open area | 1% |

Air loss uses choked orifice flow into vacuum and an isothermal cabin model. Magnetic force is the effective moment multiplied by an assumed distance-dependent field gradient. Retention requires latch capacity to exceed three times the pressure force across the hole.

The scenarios compare nominal contact, disabled actuation, weak actuation, insufficient latch capacity and partial contact.

## Adjust the study

Edit `magseal_hour4_parameters.m` for latch capacity, contact quality, membrane diameter and seating delay. Edit `magseal_hour3_parameters.m` for magnetic actuation.

The 99% contact input prescribes a 1% residual opening. Physical contact, seam leakage, adhesion, impact damage and coil field distribution need further modeling and testing. The link between the independent guides and continuous cover is conceptual.

## References

NASA's ionomer/elastomer shielding experiments provide background for self-sealing materials. MAGSEAL's membrane and actuation parameters remain design assumptions.

- [NASA — Alternative MMOD Shielding Concepts](https://ntrs.nasa.gov/citations/20230014767)
- [MIT — Magnetic soft-material research](https://dspace.mit.edu/entities/publication/0f6e4b3f-ade7-4057-8a6f-390405f815ec)
