# MAGSEAL exterior self-healing layer simulation

## Run

MATLAB users should extract this folder, open it as Current Folder, and run `run_magseal_exterior`. The runner produces six case CSVs, a summary table, and a four-panel figure under `matlab_results`. Base MATLAB with jsondecode, read/write tables, tiledlayout and exportgraphics is required. No additional toolbox is used.

The executed reference is Python. Install numpy, scipy and matplotlib, then run `python simulate.py`. Its results are already included under `results`. The MATLAB implementation follows the same equations and shared parameter JSON, and recalculates the original circular-coil force function. MATLAB was unavailable here, so the MATLAB runner has not been executed. Python results and numerical checks were executed successfully.

## Proposed placement

From space toward the cabin, the layers are an exterior self-healing polymer, the spacecraft pressure hull, and MENP repair material on the cabin side. A cabin-side coil is assumed already centered over the damage. The 6 mm impact opening initially penetrates both the hull and exterior polymer. Exterior recovery begins only after the puncture. This is a proposed MAGSEAL architecture.

There is no retaining cap, plunger, latch, or fabric mesh in this version. The exterior film and its attachment provide the assumed support. The original guided-carrier motion calculation is retained as a conditional delivery-time surrogate. It does not prove that freely dispersed MENPs carry resin across the hole.

## Baseline assumptions

| Quantity | Value | Status |
|---|---:|---|
| Puncture diameter | 6 mm | User baseline |
| Hull thickness | 2 mm | Inherited assumption |
| Cabin volume | 20 m³ | Inherited example, not a Mars habitat design |
| Initial pressure | 101.325 kPa | Inherited assumption |
| Gas temperature | 293.15 K | Constant, isothermal model |
| Exterior pressure | 0 Pa | Ideal vacuum |
| Exterior polymer thickness | 0.5 mm | New design assumption |
| Exterior recovery delay / time constant | 1 s / 10 s | Unmeasured prescribed kinetics |
| Residual exterior open area | 0.1% of original area | Optimistic assumption, not zero leakage |
| Exterior film plus attachment capacity | 10 N | Assumed input, not computed from thickness |
| Preliminary load multiplier | 3 | Screening assumption |
| Coil | 200 turns, 4 mm radius, 2 A | Inherited thin-loop idealization |
| Coil center distance from material plane | 4 mm | Position assumed achieved |
| Effective carrier dipole moment | 0.001794 A m² | Inherited conditional material estimate |
| Local repair inventory | 110 µL | Finite assumed supply |
| Delivery rate after arrival | 1 µL/s | Assumed, not solved from magnetic fluid dynamics |
| Delivery working life | 120 s | Assumed |
| Initial viscosity | 3 Pa s | Assumed |
| Cure time constant | 90 s after arrival | Assumed trigger and kinetics |
| Final bond shear strength | 0.4 MPa | Assumed |
| Time step / duration | 0.02 s / 600 s | Numerical choices |
| Gas leak screening threshold | 1 mg/s | Illustrative threshold, not a flight requirement |

The exterior layer is assumed to recover by an appropriate material mechanism. No oxygen, heat, or UV supply is modeled. Material selection must establish the activation mechanism and whether the prescribed recovery is possible in vacuum. MENPs are magnetoelectric particles, but this model uses only an assumed magnetic dipole response.

## Equations and model scope

1. Gas leakage is an ideal choked-orifice estimate into vacuum. `mdot = Cd Aeff P sqrt(gamma/(R T)) [2/(gamma+1)]^[(gamma+1)/(2(gamma-1))]`. Cabin pressure follows an isothermal fixed-volume ideal gas, updated exponentially within each time step. Cabin repressurization is absent.
2. Exterior aperture area fraction is prescribed as `a = a_floor + (1-a_floor) exp(-max(0,t-t_puncture-delay)/tau_heal)`. Its aperture radius is the original radius multiplied by `sqrt(a)`. This does not resolve impact damage, film deformation or molecular healing.
3. The exterior recovery is credited only when its assumed film/attachment capacity exceeds `3 P0 A_hole`. A failed support case conservatively retains the original hole area. At baseline the pressure force is 2.865 N and the screening target is 8.595 N. This capacity gate is a hypothesis, not structural verification.
4. Original thin-loop Biot–Savart field and finite-difference gradients are retained. `F = m_eff grad(|B|)`. A representative guided carrier moves from radius 8 mm to 3 mm with assumed friction and damping. Arrival at the rim does not resolve traversal of the hole or formation of a bridge. Normal force is toward the cabin-side coil, so physical confinement remains unresolved.
5. Repair delivery starts after arrival, at the assumed finite rate. No delivery is credited without arrival. The rate is not inferred from the coil's magnetic force. Filling is bounded by bore volume and available inventory.
6. Extrusion is a Newtonian capillary screening estimate through the exterior opening. `Qloss = pi r_open^4 P/(8 mu L) (1-cure)^3`. `L` is the combined hull/film thickness when support is credited. This assumes full pressure across the mobile material, ignores capillary pressure, wetting, non-Newtonian yield stress and gas-liquid interface shape, and can overestimate actual loss. Loss is capped at available repair volume each step. Polymer inventory is explicitly conserved as used = retained + expelled.
7. Cure is prescribed from arrival as `cure = 1-exp(-(t-t_arrival)/tau_cure)`. All local material shares that clock, an approximate premixed-batch representation. The factor `(1-cure)^3` phenomenologically reduces mobility. Cure is not a measured resin model.
8. Gas aperture is an empirical proxy `Aeff/A0 = min(1, a(1-fill*cure) + leak_floor*fill*cure)`. Fill is retained volume divided by hole-bore volume. This assumes deposited material obstructs the leak in proportion to fill and cure. Spatial void connectivity and interface leaks are not resolved. Thus the reported leak rate depends strongly on this assumed closure law.
9. Bond capacity is an optimistic scalar proxy `tau_bond pi d h fill cure²`. Full bore-wall wetting and shear transfer are assumed. It does not resolve peel, irregular impact edges, crack growth or failure after loss of exterior support. No flight-safe classification is produced.
10. Coil power is `I²R` with a lumped thermal model. The coil turns off at carrier arrival. Thus this version explicitly relies on exterior support for subsequent retention. Positioning power, electronics, deployment and thermal-control hardware are omitted from the energy result.

## Scenarios

Six cases include untreated damage, exterior recovery alone, combined nominal assumptions, no exterior healing, slow recovery with a 60 s time constant, and an exterior support capacity reduced to 1 N. The latter two complete-failure cases conservatively restore an open 6 mm hole. No success is forced by stopping leakage at an event.

## Results at 600 seconds

| Case | Air lost | Final leakage | Retained repair polymer |
|---|---:|---:|---:|
| Untreated | 2,849.75 g | 4,471.68 mg/s | 0 µL |
| Exterior only | 58.75 g | 5.059 mg/s | 0 µL |
| Combined nominal assumptions | 56.67 g | 0.670 mg/s | 49.63 µL |
| Exterior does not heal | 2,849.75 g | 4,471.68 mg/s | 0 µL |
| Exterior heals slowly | 310.13 g | 5.245 mg/s | 0 µL |
| Exterior attachment fails | 2,849.75 g | 4,471.68 mg/s | 0 µL |

The nominal bore volume is 56.55 µL. Nominal retained volume is only 87.8% of that volume. The model therefore does not predict a fully filled bore. Nominal arrival occurs at 9.26 s on a clock where puncture occurs at 2 s. The assumed coil model consumes 8.99 J and peaks at 29.59 °C. These are actuator-only outputs.

Most of the initial air-loss reduction comes from the assumed exterior recovery. Adding MENP delivery reduces final leakage in the chosen empirical model, but saves only about 2.08 g of additional air over exterior recovery alone in the first 600 s. This comparison is essential when assessing the benefit of magnetic delivery. The combined case satisfies the chosen leak-rate screening number, but that does not establish an airtight, structurally qualified or flight-ready seal.

Slow exterior recovery allows the entire 110 µL repair supply to escape before retention. The design therefore remains sensitive to recovery speed, attachment strength, rheology and actual delivery behavior.

## Mass and economics

At an assumed density of 1000 kg/m³ and thickness 0.5 mm, exterior polymer adds 0.5 kg/m². A hypothetical 100 m² coverage adds 50 kg before adhesive, reinforcement, thermal protection, repair inventory, sensors and deployment hardware. This is a mass estimate only. There are no verified manufacturing, qualification, launch or mission cost inputs, so the simulator makes no economic viability claim.

## Verification

The executed reference checks material conservation, pressure monotonicity, inventory bounds, the untreated analytical pressure-decay solution, and absence of delivery with zero coil current. Halving the time step checks sensitivity of nominal retained volume. See `results/verification.txt`.

## Research grounding and correction

NASA's 2023 *Alternative MMOD Shielding Concepts* reports self-sealing shielding configurations containing ionomer films and elastomers that stopped leaks for pressure-shell holes up to 6 mm under pressure differences up to one atmosphere. This is more directly relevant than the earlier cited 2 mm spacesuit result. It does not establish the performance of this exterior coating or MENP delivery system. The simplified kinetics, thickness and capacity here are not fitted to those experiments.
https://ntrs.nasa.gov/citations/20230014767

NASA Langley's separate multilayer concept uses solid polymer panels and a reactive middle formulation, with impact recovery and oxygen-triggered reaction. Its chemistry should not be assigned to an unspecified exterior film.
https://technology.nasa.gov/patent/LAR-TOPS-122

The previous package used a published MENP remanence comparison to estimate a carrier moment. Actual field-dependent magnetization, alignment and resin transport still require measurement.
https://pmc.ncbi.nlm.nih.gov/articles/PMC7221815/

This package replaces the previous assumed retaining collar with an exterior film hypothesis. The original coil function is reused. It is a reduced-order feasibility study and does not solve CFD, structural FEA, magnetohydrodynamics or curing chemistry.
