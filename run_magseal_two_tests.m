% MAGSEAL isolated screening tests for magnetoelectric nanoparticles
% Run from this folder: run_magseal_two_tests
% Base MATLAB R2025b, no add-on toolboxes required.
clearvars; clc;
p=magseal_dual_parameters();
guidance=magseal_test_guidance(p,true);
seal=magseal_test_seal(p,true);
growth=magseal_test_layer_growth(p,seal,guidance,true);
save('MAGSEAL_TwoTests_Results.mat','p','seal','guidance','growth');
fprintf('\nSaved MAGSEAL_TwoTests_Results.mat in Current Folder.\n');
fprintf('INTERPRETATION: A predicted low porous-film leak is NOT proof of\n');
fprintf('bonding, reliable layer-by-layer growth or spacecraft airtightness.\n');
fprintf('Field strength is calculated from idealized coil geometry; movement\n');
fprintf('assumes freely mobile particles in a fluid, not bonded wall coating.\n');
