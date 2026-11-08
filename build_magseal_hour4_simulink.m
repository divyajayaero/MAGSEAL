function model=build_magseal_hour4_simulink()
% Build a native-block Simulink pressure model using Hour 4 computed contact.
% The 12-tile motion/contact timeline is calculated in MATLAB and REPLAYED
% into Simulink via From Workspace (not re-simulated inside Simulink).
% Pressure, sensor, seal gating, and leak area ARE closed loop in Simulink.
%
% For full simultaneous model, use magseal_run_hour4_case.m in MATLAB.

model='MAGSEAL_Hour4';
if bdIsLoaded(model)
    fprintf('%s is already loaded; reusing.\n',model);
    return;
end
if exist([model '.slx'],'file')
    load_system(model);open_system(model);
    fprintf('Loaded existing %s.slx\n',model);
    return;
end
p=magseal_parameters();
assignin('base','p',p);
flowCoefficient=p.Cd*sqrt(p.gamma/(p.R*p.T))* ...
    (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
assignin('base','flowCoefficient',flowCoefficient);
new_system(model);open_system(model);
set_param(model,'StopTime','p.tEnd','SolverType','Fixed-step', ...
    'Solver','ode4','FixedStep','p.dt');
b=@(name)[model '/' name];

add_block('simulink/Sources/Step',b('Puncture area'), ...
    'Position',[40 40 130 85], ...
    'Time','p.tPuncture','Before','0','After','p.area');
add_block('simulink/Sources/From Workspace',b('MATLAB computed cover fraction'), ...
    'Position',[35 135 160 180], ...
    'VariableName','magsealSealProfile','Interpolate','off');
add_block('simulink/Sources/Constant',b('One'), ...
    'Position',[260 225 310 260],'Value','1');
add_block('simulink/Math Operations/Product',b('Seal fraction enabled by sensor'), ...
    'Position',[250 130 290 180]);
add_block('simulink/Math Operations/Sum',b('Open fraction'), ...
    'Position',[365 190 400 240],'Inputs','+-');
add_block('simulink/Math Operations/Product',b('Effective puncture area'), ...
    'Position',[475 65 515 115]);
add_block('simulink/Math Operations/Product',b('Pressure times area'), ...
    'Position',[590 65 630 115]);
add_block('simulink/Math Operations/Gain',b('Choked flow'), ...
    'Position',[685 65 795 115],'Gain','flowCoefficient');
add_block('simulink/Math Operations/Gain',b('Pressure derivative'), ...
    'Position',[850 65 955 115],'Gain','-p.R*p.T/p.V');
add_block('simulink/Continuous/Integrator',b('Cabin pressure'), ...
    'Position',[1000 65 1040 115],'InitialCondition','p.P0');
add_block('simulink/Sources/Constant',b('Sensor threshold'), ...
    'Position',[895 240 995 275],'Value','p.P0-p.sensorDropPa');
add_block('simulink/Logic and Bit Operations/Relational Operator', ...
    b('Leak detected'), 'Position',[1070 185 1115 240], 'Operator','<=');

add_block('simulink/Sinks/To Workspace',b('Log H4 pressure'), ...
    'Position',[1095 45 1220 75], ...
    'VariableName','magsealH4Pressure','SaveFormat','Timeseries');
add_block('simulink/Sinks/To Workspace',b('Log H4 sensor'), ...
    'Position',[1180 190 1305 220], ...
    'VariableName','magsealH4Sensor','SaveFormat','Timeseries');
add_block('simulink/Sinks/To Workspace',b('Log H4 flow'), ...
    'Position',[690 12 800 45], ...
    'VariableName','magsealH4Flow','SaveFormat','Timeseries');
add_block('simulink/Sinks/To Workspace',b('Log H4 effective area'), ...
    'Position',[470 12 575 45], ...
    'VariableName','magsealH4Area','SaveFormat','Timeseries');

add_line(model,'Puncture area/1','Effective puncture area/1','autorouting','on');
add_line(model,'MATLAB computed cover fraction/1','Seal fraction enabled by sensor/2','autorouting','on');
add_line(model,'Leak detected/1','Seal fraction enabled by sensor/1','autorouting','on');
add_line(model,'One/1','Open fraction/1','autorouting','on');
add_line(model,'Seal fraction enabled by sensor/1','Open fraction/2','autorouting','on');
add_line(model,'Open fraction/1','Effective puncture area/2','autorouting','on');
add_line(model,'Effective puncture area/1','Pressure times area/2','autorouting','on');
add_line(model,'Cabin pressure/1','Pressure times area/1','autorouting','on');
add_line(model,'Pressure times area/1','Choked flow/1','autorouting','on');
add_line(model,'Choked flow/1','Pressure derivative/1','autorouting','on');
add_line(model,'Pressure derivative/1','Cabin pressure/1','autorouting','on');
add_line(model,'Cabin pressure/1','Leak detected/1','autorouting','on');
add_line(model,'Sensor threshold/1','Leak detected/2','autorouting','on');
add_line(model,'Cabin pressure/1','Log H4 pressure/1','autorouting','on');
add_line(model,'Leak detected/1','Log H4 sensor/1','autorouting','on');
add_line(model,'Choked flow/1','Log H4 flow/1','autorouting','on');
add_line(model,'Effective puncture area/1','Log H4 effective area/1','autorouting','on');
save_system(model);
fprintf('Created %s.slx (native Simulink pressure loop + replayed MATLAB contact)\n',model);
end
