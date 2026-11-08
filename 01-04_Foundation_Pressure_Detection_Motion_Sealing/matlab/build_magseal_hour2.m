% MAGSEAL HOUR 2: Build a sensor-driven Simulink model automatically.
% Requires Simulink. Keep magseal_parameters.m in the same folder.
% This is a control-command demonstration; sealing is NOT implemented yet.
clc;
p = magseal_parameters();
assignin('base','p',p);

model = 'MAGSEAL_Hour2';
if bdIsLoaded(model), close_system(model,0); end
if exist([model '.slx'],'file')
    error('File %s.slx already exists. Rename/move it before rerunning this builder.',model);
end
new_system(model);
open_system(model);
set_param(model, 'StopTime', 'p.tEnd', ...
                 'SolverType','Fixed-step', ...
                 'Solver','ode4', ...
                 'FixedStep','p.dt');

% To vacuum, flow is choked and proportional to internal absolute pressure.
% m_dot [kg/s] = Cd*A*P*sqrt(gamma/(R*T))*(2/(gamma+1))^((gamma+1)/(2*(gamma-1)))
flowCoefficient = p.Cd * sqrt(p.gamma/(p.R*p.T)) * ...
   (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
assignin('base','flowCoefficient',flowCoefficient);

block = @(name) [model '/' name];
add_block('simulink/Sources/Step',block('Puncture at 2 s'),...
    'Position',[40 70 105 110], ...
    'Time','p.tPuncture','Before','0','After','p.area');
add_block('simulink/Math Operations/Product',block('P times area'),...
    'Position',[250 90 280 130]);
add_block('simulink/Math Operations/Gain',block('Choked flow coefficient'),...
    'Position',[315 90 415 130],'Gain','flowCoefficient');
add_block('simulink/Math Operations/Gain',block('dP dt from mass loss'),...
    'Position',[455 90 550 130],'Gain','-p.R*p.T/p.V');
add_block('simulink/Continuous/Integrator',block('Cabin pressure Pa'),...
    'Position',[600 90 635 130],'InitialCondition','p.P0');

add_block('simulink/Sources/Constant',block('Pressure trigger Pa'),...
    'Position',[460 235 555 265],...
    'Value','p.P0-p.sensorDropPa');
add_block('simulink/Logic and Bit Operations/Relational Operator',...
    block('Pressure below threshold'),...
    'Position',[615 210 670 260],'Operator','<=');

% Detection of the first threshold crossing automatically commands coil on.
% At this stage no magnetic field, moving patches, or repaired leak is modeled.
add_block('simulink/Sinks/Display',block('Coil command 0 or 1'),...
    'Position',[755 210 845 255]);
add_block('simulink/Sinks/To Workspace',block('Log pressure'),...
    'Position',[755 65 865 100],...
    'VariableName','magsealPressure','SaveFormat','Timeseries');
add_block('simulink/Sinks/To Workspace',block('Log coil command'),...
    'Position',[755 270 865 305],...
    'VariableName','magsealCoilCommand','SaveFormat','Timeseries');
add_block('simulink/Sinks/To Workspace',block('Log leak flow'),...
    'Position',[455 15 565 50],...
    'VariableName','magsealLeakFlow','SaveFormat','Timeseries');
add_block('simulink/Signal Routing/Mux',block('Pressure and trigger Scope mux'),...
    'Position',[915 95 920 175],'Inputs','2');
add_block('simulink/Sinks/Scope',block('Pressure plus command scope'),...
    'Position',[960 105 1005 145]);

add_line(model,'Puncture at 2 s/1','P times area/2','autorouting','on');
add_line(model,'Cabin pressure Pa/1','P times area/1','autorouting','on');
add_line(model,'P times area/1','Choked flow coefficient/1','autorouting','on');
add_line(model,'Choked flow coefficient/1','dP dt from mass loss/1','autorouting','on');
add_line(model,'dP dt from mass loss/1','Cabin pressure Pa/1','autorouting','on');
add_line(model,'Choked flow coefficient/1','Log leak flow/1','autorouting','on');
add_line(model,'Cabin pressure Pa/1','Log pressure/1','autorouting','on');
add_line(model,'Cabin pressure Pa/1','Pressure below threshold/1','autorouting','on');
add_line(model,'Pressure trigger Pa/1','Pressure below threshold/2','autorouting','on');
add_line(model,'Pressure below threshold/1','Coil command 0 or 1/1','autorouting','on');
add_line(model,'Pressure below threshold/1','Log coil command/1','autorouting','on');
add_line(model,'Cabin pressure Pa/1','Pressure and trigger Scope mux/1','autorouting','on');
add_line(model,'Pressure below threshold/1','Pressure and trigger Scope mux/2','autorouting','on');
add_line(model,'Pressure and trigger Scope mux/1','Pressure plus command scope/1','autorouting','on');

save_system(model);
fprintf('\nCreated %s.slx\n',model);
fprintf('Run sim(''%s'') or press Run in Simulink.\n',model);
tExpected = p.tPuncture + log(p.P0/(p.P0-p.sensorDropPa)) / ...
    ((p.R*p.T/p.V)*flowCoefficient*p.area);
fprintf('Pressure trigger: %.1f Pa. Expected command ~%.2f s after t=0.\n',...
    p.P0-p.sensorDropPa,tExpected);
fprintf('NOTE: Command is sensor output only; there is no seal response yet.\n');
