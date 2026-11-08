# MAGSEAL Autonomous Magnetic Plug — Preliminary Systems Screen

**Standalone MATLAB R2025b-compatible starter (base MATLAB); not a validated spacecraft design.**

This package explores a new repair architecture **without changing the original Hour 1–4 GitHub files**. It models a 6-mm through-wall puncture, magnetically positioned local elastomer contact head, magnetically powered small polymer dispenser, filling the *actual bore*, and delayed polymer cure.

## Run

1. Extract ZIP to a folder; set MATLAB **Current Folder** to that folder.
2. Run `run_magseal_autonomous_plug`.
3. Run `verify_magseal_autonomous_plug`.
4. Explore failures by editing **only** `magseal_plug_parameters.m`.

The runner creates two figures, `MAGSEAL_Plug_ScenarioScreen.csv`, and `MAGSEAL_Plug_Results.mat`.

## Architecture we recommend

1. Entire inner cabin hull is lined with **sealed local repair cells** (not loose powder exposed to the crew).
2. Cabin pressure sensor detects leak; an acoustic/impact grid estimates coordinates. Localization is *assumed* in the current code.
3. Local electromagnets attract **magnetic elastomer micro-petals / a tethered retaining head**. For the actuator, use a stronger ferromagnetic filler (e.g., NdFeB micro-particles) in silicone/ionomer, rather than relying on 100-nm magnetoelectric particles alone. MENPs (CoFe2O4–BaTiO3) could remain as a separate nanofiller; their special magnetoelectric function has **not** been shown necessary to seal.
4. When the contact head covers the opening, it creates a *temporary* pressure-assisted support. The software **assumes** 2% residual area; do not call this airtight.
5. A second locally actuated **magnetic plunger** pumps a *captive* adhesive/elastomer precursor (which can contain magnetite / MENPs) into the 6-mm bore and beneath the preformed head. This is literal hole filling, not nanoparticle snow falling into a void.
6. Polymer cure / crosslink locks the plug, backed by a physical retaining flange. The model **assumes** a post-cure equivalent open area of 0.01% and a 10-N latch: neither value has been measured.
7. A feedback pressure sensor should measure *residual* leakage and mark repair unsuccessful if it does not meet the independently established safety requirement.

### Why this is layer-by-layer

- Layer 1: magnetically placed, preformed silicone/ionomer retaining head (rapid temporary barrier).
- Layer 2: magnetically dispensed particle-filled polymer precursor inside the actual hole (volume deposition).
- Layer 3: crosslinked elastomer/adhesive matrix, which must bond to the wall (assumed cure kinetics).
- Layer 4: optional thin gas-barrier overlayer (NOT simulated; would require permeability data).

## Primary numerical outputs (independently cross-checked with Python)

| Quantity | Calculated value | Source of input |
|---|---:|---|
| Pressure force over a 6-mm opening at 101.325 kPa | 2.865 N | Geometry / ideal cabin pressure |
| Preliminary 3x retention force target | 8.595 N | **Assumed** factor 3 |
| Volume to fill 6-mm bore x 2-mm wall | 56.55 microliters | **Assumed** wall thickness |
| Extra 12-mm collar x 0.25-mm equivalent thickness | 28.27 microliters | **Assumed** geometry |
| Total deposited target volume | 84.82 microliters | Geometry |
| Total resin to dispense with 80% capture | 106.03 microliters | **Assumed** capture efficiency |
| Usable volume in 6–20-mm annulus, 0.25-mm deep, 50% retrievable | 142.94 microliters | **Assumed** cell geometry |
| 200 turns, 1 A, 4-mm radius, 4-mm standoff: gradient at 8 mm | 0.694 T/m | Ideal thin-loop Biot–Savart calculation |
| Same coil: gradient at 18 mm | 0.0307 T/m | Same calculation |
| Magnetic force with hypothetical 0.013116 A m^2 petal at 8 mm | 9.10 mN | **Assumed** magnetic moment, calculated field |
| Same magnetic carrier at 18 mm | 0.403 mN | Same |
| MENP-only carrier moment of 0.001794 A m^2 at 8 mm | 1.245 mN | Literature-informed remanence estimate + same field |
| 8-mm initial petal movement time | 0.358 s | Reduced-order Newtonian travel model, *not measured* |
| Gel dispenser flow | 6.34 microliters/s | ASSUMED viscosity 1.5 Pa s, no yield stress, Poiseuille |
| Time to fill (after head placement) | 16.7 s | Model with 80% capture efficiency |
| Sensor detection | 4.69 s after puncture | 100-Pa threshold, isothermal gas leak |
| Ideal 10-minute cure complete | ~624.4 s model time | **Assumed** chemistry-specific cure |
| Adiabatic 0.2-mm diameter coil wire temperature rise | ~86 K | Simple upper bound; heat sink unmodeled |

*The coil-field model is for an ideal air-core loop; actual winding geometry, magnetization, ferromagnetic backing, temperature and interactions with spacecraft instruments are not included. **Do not treat the 9.10-mN result as a verified actuator specification.***

## Scenario screening

The runner evaluates 13 cases:

1. Hybrid magnetic elastomer + captive curable sealant.
2. Loose dry MENP powder only (structural failure).
3. Magnetic microcapsules/gel but no supporting head (no retention in this architecture).
4. Magneto-elastomer head without bore-filling gel (temporary, not durable).
5. Coil current too weak.
6. Insufficient nearby repair fluid.
7. Latch too weak for static pressure.
8. Resin too viscous to fill and cure within deadline.
9. Inadequate cured edge seal (residual leak above *illustrative* target).
10. A **single** center coil attempting to attract a module from 18 mm.
11. Puncture not localized.
12. Larger 10-mm puncture (fails inventory and retention with baseline design).
13. MENP-only magnetic carrier instead of strong NdFeB-microfilled actuator.

`Passes_ASSUMED_Leak_Target` is NOT a real spacecraft qualification. It only means that this code, with **assumed residual gas leakage and cure**, predicts <=1 mg/s at 900 seconds. Actual pressure-tightness requires a measured gas leak rate, gasket contact model, outgassing/thermal testing, and structural analysis.

## Critical limitations, stated explicitly

- **Not an independent nanoparticle assembly model.** The most promising architecture uses magnetically manipulated carriers and a preformed elastomer head, while nanoparticles are confined to polymer/microcapsules. Dry particles alone do not form a mechanically validated airtight structure.
- **Does not compute cured porosity, crack propagation, wall bond strength, or permeation.** Residual leakage fractions are input assumptions. The nominal 0.01% area assumption is not zero leakage.
- **Magnetic moment is not measured.** The 0.013116 A m^2 moment assumes a 3-g NdFeB composite petal and published composite magnetization from an earlier MAGSEAL model; the whole moment remains a design estimate. MENP-only lower-moment carrier has its own failure scenario.
- **Mechanical latch 10 N is assumed**. A 2.865-N pressure force is across the hole; true contact pressure and anchoring loads may be different.
- **Petal guide friction/damping and piston efficiency are assumptions.** Gel assumed Newtonian without yield stress; real magnetorheological adhesives can be non-Newtonian and have finite cure windows.
- **The polymer cure is assumed to finish in 600 s.** Literature reports 10–20 minute pipeline repair for a specific magnetic adhesive + apparatus, not in-space MAGSEAL curing.
- **Thermal issue is substantial:** at 1 A the estimated copper coil has 2.75 W electrical heating; approximately 86 K worst-case adiabatic rise for the modeled actuation duration. Coil heat sinking and duty cycle are required. A larger wire, fewer turns, staged pulse circuits, or magnetic latches should be assessed.
- **Spacecraft constraints:** vacuum, temperature cycling, radiation, outgassing, microgravity, debris/crew contamination, power availability, electromagnetic interference, and structural damage larger than the 6-mm ideal cylinder are out of scope.
- **Not a true whole-cabin model:** simulates one locally addressable cell from a proposed distributed wall-wide repair skin.

## Evidence behind the design (not MAGSEAL validation)

1. NASA JSC (2023), *Alternative MMOD Shielding Concepts*: ionomer + elastomer shielding stopped leakage through shell holes up to 6 mm at up to about one atmosphere pressure difference. <https://ntrs.nasa.gov/citations/20230014767>
2. MIT / Kim, Zhao et al. (2018), *Printing ferromagnetic domains in soft materials*: ferromagnetic microparticles embedded in elastomers yield remotely actuated deformation. <https://dspace.mit.edu/entities/publication/0f6e4b3f-ade7-4057-8a6f-390405f815ec>
3. Crall & Keller (2017), *Targeted Self-Healing by Magnetically Guiding Microcapsules*: measured ~10x localized capsule concentration; different substrate and failure mode. <https://doi.org/10.1021/acsami.7b00459>
4. Cerdan et al. (2020), *A novel approach for closure of large damage in self-healing elastomers using magnetic particles*: field-assisted closure in Fe3O4-containing thermoreversible elastomers. <https://doi.org/10.1016/j.polymer.2020.122819>
5. Ma et al. (2021), *Magnetorheological material for pipeline and pressure vessel damage repair*: magnetic resin with carbonyl iron powder / epoxy. <https://doi.org/10.1016/j.compstruct.2021.114566>
6. Ma et al. (2026), *UV-Induced Magnetorheological Adhesive Combined with a Magnetic Sealing Device*: pipeline holes up to 10 mm, 1.5 MPa sealing pressure, 10–20-minute process in reported device. <https://doi.org/10.1021/acsapm.6c01921>

## What to model next if research-grade proof is the goal

1. Choose an actual magnetic elastomer composition; acquire its B–H or moment-vs-field curves and Young's modulus.
2. Electromagnetic FEM field map with coil conductors, yoke materials, heating and power limits, using ANSYS Maxwell or COMSOL. Couple to measured magnetic carrier force.
3. Non-Newtonian resin transport/pressure-flow model including rheology and yield stress, with mass loss to vacuum at an open puncture.
4. Solid mechanics contact: membrane deformation, seal compression, wall edge jaggedness and 3x load-bearing margin; adhesive shear and peel.
5. Gas permeation/leak testing or published rate for *same* composite and geometry. A screening assumption of 1e-4 residual area is **not** an airtightness measurement.
6. Failure studies: multiple punctures, incomplete capture, unresponsive coils, excessive heating, insufficient material after repeated repairs, and sensor localization error.
