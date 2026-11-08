function p = magseal_parameters()
% MAGSEAL reference parameters — educational concept, not flight-qualified.
p.P0 = 101325;       % initial cabin absolute pressure [Pa]
p.Pext = 0;         % exterior absolute pressure [Pa] (vacuum idealization)
p.T = 293.15;       % isothermal air temperature [K]
p.V = 20;           % cabin volume [m^3]
p.R = 287.05;       % dry air specific gas constant [J/(kg*K)]
p.gamma = 1.4;      % air heat capacity ratio [-]
p.Cd = 0.75;        % assumed orifice discharge coefficient [-]
p.holeDiameter = 0.006; % hole diameter [m] (NASA-inspired reference case)
p.area = pi*(p.holeDiameter/2)^2; % [m^2]
p.tPuncture = 2;    % opening time [s]
p.tSeal = 9;        % assumed latch time [s] - not yet predicted
p.residualAreaFraction = 0.01; % unsealed area fraction after latch
p.dt = 0.01;        % time step [s]
p.tEnd = 40;        % duration [s]
p.sensorDropPa = 100; % pressure-drop sensor threshold [Pa]
end
