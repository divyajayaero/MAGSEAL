MAGSEAL — Guided module motion

This earlier model follows 12 repair modules moving along guides after a pressure-drop sensor activates the coil.

Run
Open the matlab folder in MATLAB and run run_magseal_hour3.
Simulink is required. The script creates MAGSEAL_Hour2.slx if needed.

Inputs
magseal_hour3_parameters.m contains field strength, magnetic moment, friction and damping.
magseal_parameters.m contains cabin conditions and the detection threshold.

Results
The model reports activation time, module travel and arrival. Magnetic force must overcome static friction before movement begins. Cabin leakage continues throughout this study because arrival is not coupled to sealing.

Model scope
Travel is one-dimensional. Field gradients, alignment, friction and module properties are assumptions. Contact, adhesion and pressure retention require separate evaluation. Check the puncture diameter in the parameters before comparing this historical study with the current 6 mm design.

Verification used source review and independent numerical calculations. MATLAB/Simulink execution was not verified when this study was prepared.
