# MAGSEAL — HOUR 4: MEMBRANE + RETENTION + PRESSURE FEEDBACK

## Start in MATLAB (base MATLAB required)

1. Extract the ZIP to `MAGSEAL_Hour4` and set MATLAB **Current Folder** to it.
2. Keep the Hour 3 `.m` files here; the supplied copies are already updated to the 6-mm case.
3. Type `run_magseal_hour4` in the Command Window.
4. Type `verify_magseal_hour4` to run six automated physical/mathematical consistency checks.
5. **Optional** (requires Simulink): type `run_magseal_hour4_simulink` to build `MAGSEAL_Hour4.slx` and compare its pressure simulation with MATLAB.

**No need to edit the old `MAGSEAL_Hour2.slx`.** Its original sensor remains separate. `MAGSEAL_Hour4.slx` is newly generated.

## How it is coupled

Puncture at 2 s → air mass loss → cabin pressure → 100-Pa sensor threshold → coil rise → magnetic force and independent 1D travel of 12 modules → all 12 at target → seating delay → membrane geometry + latch capacity → contact-quality assumption → area available for airflow → air mass loss.

The MATLAB solver computes every state in one time loop; there is no hard-coded contact time. In the OPTIONAL Simulink model the calculated contact timeline is *replayed* from MATLAB; Simulink closes its own pressure/sensor/area loop but does **not** recalculate 12 tile trajectories inside the Simulink diagram. This is intentionally disclosed so the claim remains accurate.

## Numerical starting design

- **Keep:** 6-mm puncture, 101325 Pa cabin pressure, 20 m³ isothermal cabin, 100 Pa detection threshold, 12 modules each of 3 g, 8–18 mm guided travel, 0.013116 A·m² per module (literature-INFORMED estimate), hypothetical 0.50 T/m at 18 mm; 2 mN static friction.
- **Add (assumptions):** 12-mm-diameter *continuous* cover with 3-mm radial overlap around a 6-mm hole, required overlap 2 mm, 0.30-s seating delay, 10-N idealized retaining latch, safety factor 3 on static pressure load, and contact quality of 99% (meaning **1% residual OPEN AREA**).
- **Source for general sealing concept:** NASA JSC `Alternative MMOD Shielding Concepts` (2023), https://ntrs.nasa.gov/api/citations/20230014767/downloads/MMOD_shielding_alternatives_IOC2_6086_v2.pdf . NASA reported ionomer/elastomer shield specimens retaining pressure through small holes, including example 5-mm hole. NASA did **not** demonstrate MAGSEAL magnetic tile movement, our exact membrane, or this 99% contact quality.
- **Source for general magnetic soft material concept:** MIT 2018 Yoonho Kim thesis https://dspace.mit.edu/entities/publication/0f6e4b3f-ade7-4057-8a6f-390405f815ec . MIT did **not** validate the MAGSEAL field strength.

## Equations

Choked mass flow to ideal vacuum: `m_dot = Cd * A_eff * P * sqrt(gamma/(R*T)) * (2/(gamma+1))^((gamma+1)/(2*(gamma-1)))`.

Isothermal cabin: `P_next = P - dt*(R*T/V)*m_dot`.

Magnetic force on each module: `F_i = m_eff_i * G_i(gap_i) * fieldFraction`, with **assumed** gap dependence `G_i = gradientRef * (gapRef/(gapRef+gap_i))^gradientExponent`.

Pressure loading on cover: `F_P = (P-Pext)*pi*d_hole^2/4`; retained iff `latchCapacity >= retentionSafetyFactor * F_P`.

Geometry condition: radial overlap `(membraneDiameter-holeDiameter)/2 >= requiredRadialOverlap`.

After ALL modules arrive, enough time has elapsed to seat the membrane, and the geometry and retention conditions pass: `A_eff = A_hole*(1-contactQuality)`. Otherwise `A_eff = A_hole` for times after puncture.

**99% contact quality is not an empirical seal-efficiency number.** The code does not solve gasket deformation/contact stresses, fluid flow through seams, adhesive behavior, thermal cycling, micrometeoroid damage to the membrane, or electromagnet Maxwell fields. It also does not simulate 2D positions or the actual mechanism that couples 12 independent guides to the continuous cover.

## Five scenarios in `run_magseal_hour4.m`

1. Assumed good contact — all tiles arrive, cover meets geometry, latch passes, 1% area remains.
2. No magnetic actuation — no tile arrival, 100% area open.
3. Weak magnetic field — no tile arrival, 100% area open.
4. Underrated latch (4 N vs ~8.6 N target) — tiles arrive but NO sealing.
5. Partial contact (60%) — all tiles arrive but 40% residual area leaks.

## Change parameters for live demo

Edit **only** `magseal_hour4_parameters.m` for Hour 4 design inputs:

- `s.latchCapacity = 10.0` → try `4.0` to show retention failure.
- `s.contactQuality = 0.99` → try `0.60` for partial contact.
- `s.membraneDiameter = 0.012` → try `0.009` to fail the 2-mm overlap requirement.
- `s.seatingDelay = 0.30` → try `2.00` to demonstrate slow seating.

Other scripts inherit the same Hour 3 magnetic model unchanged. For magnetic strength changes, edit `magseal_hour3_parameters.m` (`q.fieldScale`).

## Key caution

The plots demonstrate what would happen **IF** the assumed coil forces, 10-N retention, and 99% coverage are met. They do not prove those three hardware conditions can be achieved together. NASA's self-sealing test is an independent proof of a different mechanism, not a MAGSEAL validation.
