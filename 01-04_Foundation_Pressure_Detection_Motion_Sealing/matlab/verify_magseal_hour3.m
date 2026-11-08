% MAGSEAL HOUR 3 SELF-CHECK — execute in MATLAB with Simulink installed.
% Automatically exercises the five Hour 3 success criteria.
% Source/numerical review completed separately; this performs real MATLAB tests.
clearvars; clc;
p=magseal_parameters();
q=magseal_hour3_parameters();
q.fieldScale=1;  % force a consistent nominal test, regardless of user experiments
assignin('base','p',p);
flowCoefficient=p.Cd*sqrt(p.gamma/(p.R*p.T))* ...
    (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
assignin('base','flowCoefficient',flowCoefficient);
if ~exist('MAGSEAL_Hour2.slx','file')
    build_magseal_hour2;
end
simOut=sim('MAGSEAL_Hour2');
P=simOut.get('magsealPressure');
cmd=simOut.get('magsealCoilCommand');
t=(0:p.dt:p.tEnd)';
command=interp1(cmd.Time,double(cmd.Data(:)),t,'previous','extrap');
command=min(1,max(0,command));
firstOn=find(command>=0.5,1,'first');
assert(~isempty(firstOn),'FAIL 1: sensor never activated electromagnet command');
tDetected=t(firstOn);
expectedDetect = p.tPuncture + log(p.P0/(p.P0-p.sensorDropPa)) / ...
    ((p.R*p.T/p.V)*flowCoefficient*p.area);
assert(tDetected>p.tPuncture && abs(tDetected-expectedDetect)<0.15, ...
    'FAIL 1: sensor switch does not occur near expected time');
assert(all(command(t<p.tPuncture)<0.5), ...
    'FAIL 1: coil is active before puncture');
fprintf('PASS 1: Simulink detection triggers command at t=%.3f s.\n',tDetected);

base=magseal_simulate_tiles(t,command,q);
assert(isequal(size(base.gap),[numel(t),12]), ...
    'FAIL 2: 12 trajectories not present');
assert(isequal(size(base.magneticForce),[numel(t),12]), ...
    'FAIL 2: magnetic forces not calculated for 12 modules');
fprintf('PASS 2: 12 trajectories and 12 force histories calculated.\n');

before=find(t<tDetected);
initial=q.initialGap(:)';
assert(all(abs(base.gap(before,:)-initial)<1e-12,'all'), ...
    'FAIL 3: tile motion occurred before activation');
assert(all(diff(base.gap,1,1)<=1e-12,'all'), ...
    'FAIL 3: tiles move away from target');
fprintf('PASS 3: no module motion before activation; travel is monotonic.\n');

assert(base.numArrived==12 && all(isfinite(base.arrivalTime)), ...
    'FAIL 4: not all baseline modules arrived');
assert(all(base.arrivalTime>tDetected), ...
    'FAIL 4: arrival occurred before activation');
fprintf('PASS 4: 12/12 modules arrive. First %.3f s; last %.3f s.\n', ...
    min(base.arrivalTime),max(base.arrivalTime));

qWeak=q; qWeak.fieldScale=0.05;
weak=magseal_simulate_tiles(t,command,qWeak);
off=magseal_simulate_tiles(t,zeros(size(command)),q);
assert(weak.numArrived==0 && off.numArrived==0, ...
    'FAIL 5: weak/disabled field should prevent arrivals');
assert(all(abs(weak.gap(end,:)-initial)<1e-12), ...
    'FAIL 5: weak field moves the modules unexpectedly');
assert(all(abs(off.gap(end,:)-initial)<1e-12), ...
    'FAIL 5: field-off modules moved unexpectedly');
fprintf('PASS 5: weak field 0/12; field disabled 0/12.\n');

fprintf('\nALL FIVE MAGSEAL HOUR 3 SELF-CHECKS PASSED.\n');
fprintf('Reminder: arrival does not demonstrate airtightness, pressure retention, or realistic magnetic field strength.\n');
