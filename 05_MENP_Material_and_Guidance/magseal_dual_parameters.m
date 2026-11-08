function p = magseal_dual_parameters()
% MAGSEAL two-test screening model. SI units throughout.
% LITERATURE VALUES (different published samples; do not treat as a matched device dataset):
% 2019/2020 CoFe2O4-BaTiO3 comparison reported Mr=5.98 emu/g,
% Ms=33.9 emu/g. 1 emu/g = 1 A*m^2/kg.
% https://pmc.ncbi.nlm.nih.gov/articles/PMC7221815/ Table 4
% Densities are approximate literature values, not an in-house measurement:
% https://pmc.ncbi.nlm.nih.gov/articles/PMC9120189/ Table 1
% NASA: self-sealing ionomer/elastomer concepts for holes up to ~6 mm.
% https://ntrs.nasa.gov/citations/20230014767
p.dHole = 0.006;
p.dPatch = 0.012;
p.P0 = 101325; p.Poutside = 0;
p.T = 293.15; p.Rair = 287.05; p.gamma = 1.4;
p.Cd = 0.75; p.muAir = 1.81e-5;
p.particleDiameter = 100e-9; % ASSUMED illustrative MENP diameter
p.ferriteMassFraction = 0.60; % value for cited CoFe2O4/BaTiO3 example
p.rhoFerrite = 6060; p.rhoBTO = 5700; % kg/m^3, literature proxies
p.rhoMENP = 1/(p.ferriteMassFraction/p.rhoFerrite + ...
    (1-p.ferriteMassFraction)/p.rhoBTO);
p.MrMass = 5.98; % A*m^2/kg measured sample remanence
p.MsMass = 33.9; % A*m^2/kg measured sample saturation, NOT reached at arbitrary B
p.momentAlignment = 0.5; % ASSUMPTION
p.designSafetyFactor = 3; % ASSUMPTION, NOT NASA standard
% Wall-wide coating: only a nearby donor annulus is accessible.
p.donorOuterRadius = 0.020; % 20 mm from hole center; ASSUMED
p.coatingThickness = 50e-6; % 50 um; ASSUMED
p.mobileMENPVolumeFraction = 0.20; % ASSUMED, only if mobile reservoir exists
p.layerPorosity = 0.36; % ASSUMED uniform sphere pack; bond/pore distribution unknown
p.targetStackThickness = 100e-6; % 100 um, ASSUMED
p.acceptableAirLeakKgPerS = 1e-9; % arbitrary engineering screening goal = 1 ug/s
p.exampleBondShearStrength = 200e3; % Pa, HYPOTHETICAL, not measured for MENP
p.exampleFilmTensileStrength = 5e6; % Pa, HYPOTHETICAL if polymer binder exists
p.hasContinuousBinder = false; % DEFAULT: bare magnetic particle layers
% Electromagnetic field-screen: explicit air-core coils; NOT measured.
p.coilRadius = 0.004; % m, ASSUMED
p.coilDepth = 0.004; % coil plane 4 mm behind inner wall, ASSUMED
p.coilTurns = 200; p.coilCurrent = 1; % ASSUMED
p.coilSegmentCount = 64;
p.surroundingCoilOffset = 0.008;
p.muCarrier = 1e-3; % Pa*s (water-like) very optimistic for wall material
p.muGel = 1; % Pa*s representative slow/mobile gel, not a real measured formulation
p.mobilityTime = 300; % s
p.dt = 1; % s
p.gridExtent = 0.012; p.nGrid = 81;
p.sourceParticlePos = [0.008,0]; % 8 mm from center, target at 3 mm radius
p.mu0 = 4*pi*1e-7;
end
