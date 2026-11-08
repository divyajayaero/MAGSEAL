# MAGSEAL — Two pre-design feasibility screens

**Run MATLAB:** Extract to a folder, set MATLAB Current Folder to that folder, and execute:

```matlab
run_magseal_two_tests
```

The scripts are independent of the old MAGSEAL Hour 1–4 files and intentionally **do not** modify the existing repository. No Simulink or specialized toolbox is needed for these physical screening calculations. The code was numerically cross-checked using independent Python calculations, **not executed under MATLAB** in this environment.

## Test 1 — Magnetoelectric particles deposited into a 6-mm hole

- Target a **12-mm-diameter cover** across a **6-mm hole** under **101,325 Pa** internal differential pressure.
- Uses a **CoFe2O4/BaTiO3 magnetoelectric material class**; 100-nm diameter is an illustrative assumption, not a matched experimental specimen.
- Computes conservation of particle volume from a nearby wall coating, porous-bed permeability (Kozeny–Carman), estimated mass leakage (compressible isothermal Darcy approximation), pressure force, optimistic unsupported membrane stress, and idealized overlap-bond shear strength.
- A cloud of unbound nanoparticles is **not a structural membrane or airtight seal**, even if the Darcy permeability estimate is low. The algorithm explicitly fails the mechanical seal check with `p.hasContinuousBinder = false`.
- `p.acceptableAirLeakKgPerS = 1e-9` (1 µg/s) is a **sensitivity-test criterion**, not a NASA certification threshold.
- `p.exampleBondShearStrength` and `p.exampleFilmTensileStrength` are **hypothetical** design cases. Do not claim measured values for the magnetoelectric powder.
- The model **does not solve deposition kinetics, adhesion chemistry, gaps around the perimeter, polymer crosslinking, impact damage, thermal cycling, rarefied flow, powder compaction, cohesive particle interactions, or true fluid-structure contact**.

## Test 1B — Does the layer grow quickly enough?

- The extra `magseal_test_layer_growth.m` models the **particle delivery required to accumulate a 100-µm film**, using the calculated **centered-coil magnetic drift** from Test 2 and an optimistic 100% particle capture efficiency.
- Compares 100-nm individual MENPs against *hypothetical compact 1-µm and 10-µm agglomerates*, which have different physical behavior and may jam.
- A deposited layer is not necessarily an airtight bonded layer. The time estimates **do not** simulate chemical layer-by-layer bonding. They are optimistic mass-transfer lower bounds.

## Test 2 — Electromagnetic field guidance along wall

- Uses finite circular current loops evaluated numerically using the **Biot–Savart law**; two cases: single coil under puncture (idealized but vulnerable) versus four identical coils around puncture.
- Assumed **200 turns, 1 A, 4-mm radius, 4-mm setback**. These are *not* hardware measurements, and the model assumes air cores.
- Calculates the actual **two-dimensional in-plane field gradients** at the interior wall plane. This is more meaningful than asserting an arbitrary 0.5 T/m.
- Particle magnetic moment uses published comparison values for CoFe2O4/BaTiO3 **remanence 5.98 A·m²/kg**, **saturation 33.9 A·m²/kg**, and an assumed 50% orientation efficiency.
- Uses Stokes magnetophoretic motion through a **water-viscosity** medium as an intentionally favorable *mobile-carrier scenario*; there is no reason a polymer-bound particle could move this fast. To test gel transport, change `p.muCarrier` to 1 and rerun; actual immobilized particles must be modeled as zero drift.
- A coil behind the actual hole could be destroyed; the four-coil example demonstrates why a non-optimized surrounding array can attract particles **away** from the puncture. Designing correct coils needs field optimization and likely a mechanically supported repair mechanism.
- Field-dependent magnetic hysteresis M(H), forces from particle–particle interactions, local adhesion, finite particle concentration and swarm aggregation are **not modeled**. This is *not* a COMSOL magnetic-mechanical finite-element validation.

## Evidence and caveats

| Quantity | Source | Status |
|---|---|---|
| CoFe2O4/BaTiO3 remanence 5.98 emu/g and saturation 33.9 emu/g | [Nanomaterials (2020) Table 4](https://pmc.ncbi.nlm.nih.gov/articles/PMC7221815/) | Literature measurement (reported as comparison to a prior sample) |
| CFO/BTO example densities | [Scientific Reports (2022) Table 1](https://pmc.ncbi.nlm.nih.gov/articles/PMC9120189/) | Literature constants, different specimen |
| 6-mm-scale pressure sealing with ionomer/elastomer | [NASA JSC (2023)](https://ntrs.nasa.gov/citations/20230014767) | Experimental proof for a **different** seal mechanism |
| Magnetic actuation of elastomer with ferromagnetic particles | [MIT/Nature (2018)](https://www.nature.com/articles/s41586-018-0185-0) | Demonstrated for a **different** particulate composite |
| Magnetic field from current loops | [OpenStax University Physics Vol. 2](https://openstax.org/books/university-physics-volume-2/pages/12-6-solenoids-and-toroids) | Established electromagnetics |
| Kozeny–Carman porous permeability | [Porosity–Permeability Review](https://doi.org/10.1007/s11242-018-1086-2) | Porous-bed model with limited nanoscale gas validity |
| Nanoparticle/polymer layer-by-layer gas barriers | [Barrier-film review (2015)](https://doi.org/10.1002/marc.201500055) | Demonstrated for **fabricated films**, not autonomous hull sealing |

**Important:** These references do *not* form a matched experimental dataset for one coherent nanocomposite, coil and spacecraft test. The model is a quantitative **conditional design screen**, not proof of airtight autonomous repair.

## Starting values (all design assumptions unless explicitly cited)

6-mm puncture; 12-mm cover; 100-nm MENPs; 100-µm accumulated film; porosity 0.36; 50-µm thick local reservoir coating with 20% mobile MENP volume fraction from 6–20 mm radius; 3× preliminary retention factor; 1 µg/s hypothetical leakage criterion; coil 4-mm radius, 200 turns, 1 A, 4-mm depth, and fluid viscosity 0.001 Pa·s. The magnetoelectric **electric** response is not needed for particle attraction and is not simulated.
