function q = magseal_hour3_parameters()
% HOUR 3 illustrative electromagnetic module parameters (NOT measurements).
% Units are SI. Motion is 1-D toward puncture along each guided track.
q.nTiles = 12;
q.initialGap = linspace(0.008,0.018,q.nTiles)'; % edge-to-target travel [m]
q.mass = 0.003*ones(q.nTiles,1);              % [kg] per module
q.damping = 0.60*ones(q.nTiles,1);           % [N*s/m] per module
q.staticFriction = 0.0020*ones(q.nTiles,1); % [N], magnitude
q.kineticFriction = 0.0015*ones(q.nTiles,1);% [N], magnitude
q.magneticMoment = 0.013116*ones(q.nTiles,1); % [A*m^2] literature-informed estimate
q.gradientRef = 3.92; % [T/m] at gap=0; yields 0.50 T/m at 18 mm (HYPOTHETICAL)
q.gapRef = 0.010;                            % [m]
q.gradientExponent = 2;                     % heuristic spatial decay
q.coilRiseTime = 0.25;                      % [s] first-order field rise
q.speedLimit = 0.025;                       % [m/s], assumed guided mechanism
q.fieldScale = 1;                           % vary to test weak magnets
end
