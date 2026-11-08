MAGSEAL HOUR 3 — Guided magnetic repair module dynamics

PURPOSE: Reuse the working Hour 2 pressure sensor and coil command; simulate
12 independently moving repair modules under distance-dependent magnetic
force, static/kinetic friction, damping, and finite actuator rise time.

HOW TO RUN:
1. Extract this ZIP into a NEW MAGSEAL_Hour3 folder.
2. Set MATLAB Current Folder to MAGSEAL_Hour3.
3. Run: run_magseal_hour3
   The script builds MAGSEAL_Hour2.slx if it does not yet exist.
4. Look at the MATLAB Command Window and the 3-subplot figure.

EDIT AND RE-RUN:
- magseal_hour3_parameters.m: q.fieldScale = 0 to test failed actuation.
- q.staticFriction: increase to test a stuck module.
- q.magneticMoment: vary to test force margin.
- magseal_parameters.m: p.sensorDropPa = 200 to delay activation.

HOUR 3 SUCCESS CRITERIA:
- Coils remain off until threshold crossing.
- Magnetic force starts at zero and rises after detection.
- Gaps decrease ONLY after field is sufficient to overcome static friction.
- Every arrival is reported from the simulated motion (not hardcoded).
- Weak or disabled field prevents some/all modules from reaching target.
- Cabin pressure still drops continuously: this is EXPECTED in Hour 3.

LIMITATIONS:
- 1D guided travel; NOT a free-floating nanoparticle simulation.
- q.gradientRef, moment, force decay, friction, masses are illustrative.
- Magnetic forces assume local alignment and a heuristic field gradient.
- The model does NOT verify magnetic field distribution, tile collisions,
  physical gasket contact, adhesion, airtightness, or mechanical retention.
- There is intentionally NO feedback to pressure yet (planned Hour 4).

MATLAB requires Simulink. Tested by source review and numerical cross-check,
not by executing MATLAB/Simulink in this runtime.
