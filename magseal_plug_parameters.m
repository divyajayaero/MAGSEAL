function p = magseal_plug_parameters()
% MAGSEAL autonomy design screening; SI UNITS unless explicitly specified.
% ALL quantities not named 'published' below are design assumptions.
p.P0 = 101325;             % Pa, absolute initial cabin pressure
p.Pext = 0;               % Pa, idealized exterior vacuum
p.Vcabin = 20;            % m^3
p.T = 293.15;             % K, isothermal ideal gas approximation
p.R = 287.05;             % J/(kg*K), air
p.gamma = 1.4;
p.Cd = 0.75;              % assumed discharge coefficient
p.tPuncture = 2;          % s
p.dHole = 0.006;          % m, baseline 6-mm puncture
p.tHull = 0.002;          % m, illustrative 2-mm pressure-wall thickness
p.detectDrop = 100;       % Pa, ideal pressure sensor threshold
p.controllerDelay = 0.5;  % s, assumed
p.dt = 0.1;              % s
p.tEnd = 900;             % s, allows 10-min cure to be seen

% Distributed repair reservoir: local annulus of inner cabin lining.
p.reservoirInnerRadius = 0.006; % m
p.reservoirOuterRadius = 0.020; % m
p.reservoirThickness = 0.00025; % m, mobile sealed reservoir depth
p.recoverableFraction = 0.50;   % assumed fraction deliverable after losses
p.deliveryEfficiency = 0.80;    % assumed captured fraction of gel delivered

% Hole filling, plus integral inner retaining head: NOT particles alone.
p.headDiameter = 0.012;      % m, preformed contact head diameter
p.headThickness = 0.00025;  % m, filling/support equivalent
p.requiredSafetyFactor = 3; % preliminary load factor, not flight qualified
p.latchCapacity = 10;       % N, ASSUMED mechanical retention capacity
p.enableElastomerHead = true;
p.enableFillingGel = true;
p.enableCuring = true;
p.localizationSuccessful = true;
p.cureTime = 600;           % s, ASSUMED chemistry-specific cure time
p.residualOpenBeforeCure = 0.02; % dimensionless; ASSUMED, not 'airtight'
p.residualOpenAfterCure = 0.0001;% dimensionless; ASSUMED, unvalidated
p.acceptableLeak_kgps = 1e-6;    % 1 mg/s illustrative engineering test limit

% Localized electromagnetic coil, modeled as thin circular current loops.
p.coilTurns = 200;
p.coilCurrent = 1;          % A
p.coilRadius = 0.004;      % m
p.coilOffset = 0.004;      % m behind cabin wall
p.coilSegments = 180;
p.fieldDifferenceStep = 5e-5; % m, derivative step
p.petalStartRadius = 0.008;  % m, only NEARBY petals targeted
p.petalStopRadius = 0.0035;  % m, target near 6-mm opening rim
p.farRadiusForComparison = 0.018;
p.pumpActuatorRadius = 0.006; % m, local actuator gradient evaluation
p.petalMass = 0.003;       % kg; magnetic carrier not free MENPs
p.effectiveMoment = 0.013116; % A*m^2; NdFeB-microfilled carrier ASSUMPTION
p.staticFriction = 0.002;  % N
p.kineticFriction = 0.0015;% N
p.damping = 0.60;          % N*s/m
p.maxPetalSpeed = 0.025;   % m/s, assumed mechanical stop
p.coilRiseTime = 0.25;     % s, assumed field-response time
p.mechanicalPumpEfficiency = 0.35; % assumed transmission efficiency
p.pumpPlungerRadius = 0.002;    % m
p.channelRadius = 0.00075;     % m
p.channelLength = 0.006;       % m
p.gelViscosity = 1.5;          % Pa*s, Newtonian approximation; NOT measured
p.maxMagnetRunSeconds = 30;     % s, illustrative duty/thermal budget
p.maxAdiabaticRise_K = 30;      % K, screening concern threshold; not certification

% Coil copper resistance screening. No heat sink modeled.
p.wireRadius = 0.00010;          % m, 0.2-mm diameter copper
p.copperResistivity = 1.72e-8;  % Ohm*m, near room temperature
p.copperDensity = 8960;        % kg/m^3
p.copperSpecificHeat = 385;    % J/(kg*K)
end
