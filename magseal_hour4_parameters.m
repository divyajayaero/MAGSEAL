function s = magseal_hour4_parameters()
% HOUR 4: Assumed continuous-membrane contact + retention model.
% These values are DESIGN SCENARIOS, NOT NASA data or measured MAGSEAL values.
s.membraneDiameter = 0.012;      % [m] continuous cover diameter (assumed)
s.requiredRadialOverlap = 0.002; % [m] minimum overlap around hole (assumed)
s.latchCapacity = 10.0;         % [N] maximum assumed hold capacity
s.retentionSafetyFactor = 3.0;  % [-] conceptual target against pressure load
s.seatingDelay = 0.30;          % [s] time after ALL 12 modules arrive (assumed)
s.contactQuality = 0.99;        % [-] fraction of opening blocked after seating
                                    % i.e. 1% residual leak AREA, assumed
end
