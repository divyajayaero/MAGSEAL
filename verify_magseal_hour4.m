% MAGSEAL HOUR 4 - automated MATLAB numerical consistency checks.
% Run AFTER run_magseal_hour4, or standalone.
clearvars; clc;
p=magseal_parameters(); q=magseal_hour3_parameters(); s=magseal_hour4_parameters();
a=magseal_run_hour4_case(p,q,s);
qOff=q;qOff.fieldScale=0;b=magseal_run_hour4_case(p,qOff,s);
qWeak=q;qWeak.fieldScale=0.05;w=magseal_run_hour4_case(p,qWeak,s);
sBad=s;sBad.latchCapacity=4;l=magseal_run_hour4_case(p,q,sBad);
sPartial=s;sPartial.contactQuality=0.60;c=magseal_run_hour4_case(p,q,sPartial);

assert(abs(p.holeDiameter-0.006)<1e-9,'FAIL: must use 6-mm puncture.');
assert(abs(p.P0*p.area-2.8643)<0.005,'FAIL 1: puncture load incorrect.');
assert(s.latchCapacity>=s.retentionSafetyFactor*p.P0*p.area, ...
    'FAIL 1: baseline retention capacity is insufficient.');
assert(a.coverageOK,'FAIL 1: continuous membrane coverage is insufficient.');
fprintf('PASS 1: geometry and initial pressure-load check (%.3f N; design target %.3f N).\n', ...
    p.P0*p.area,s.retentionSafetyFactor*p.P0*p.area);

expected=p.tPuncture + log(p.P0/(p.P0-p.sensorDropPa))/ ...
    ((p.R*p.T/p.V)*a.flowCoefficient*p.area);
assert(abs(a.detectionTime-expected)<0.12, 'FAIL 2: sensor timing inaccurate.');
assert(~any(a.command(a.t<p.tPuncture)),'FAIL 2: early sensor activation.');
fprintf('PASS 2: pressure-triggered detection %.2f s.\n',a.detectionTime);

assert(a.nArrived==q.nTiles && isfinite(a.lastArrivalTime), ...
    'FAIL 3: not all modules arrive under baseline parameters.');
assert(isfinite(a.sealEngagementTime) && ...
    a.sealEngagementTime>=a.lastArrivalTime+s.seatingDelay-1e-10, ...
    'FAIL 3: seal engages before seating.');
assert(~any(a.blockedFraction(a.t<a.sealEngagementTime)>0), ...
    'FAIL 3: leak reduction before contact.');
fprintf('PASS 3: 12/12 arrive at %.2f s; contact engages at %.2f s.\n', ...
    a.lastArrivalTime,a.sealEngagementTime);

assert(a.effectiveArea(end)/p.area <0.011 && a.effectiveArea(end)/p.area>0.009, ...
    'FAIL 4: baseline area reduction not equal to assumed 1%%.');
assert(a.pressurePa(end)>b.pressurePa(end)+100, ...
    'FAIL 4: repaired pressure does not improve on no-repair case.');
assert(all(diff(a.pressurePa)<=1e-8), ...
    'FAIL 4: cabin pressure increases despite no replenishment.');
fprintf('PASS 4: 1%% assumed residual area reduces leak and slows pressure loss.\n');

assert(w.nArrived==0 && ~any(w.engaged),'FAIL 5: weak-field failure did not hold.');
assert(b.nArrived==0 && ~any(b.engaged),'FAIL 5: no-actuation failure did not hold.');
assert(l.nArrived==q.nTiles && ~any(l.engaged), ...
    'FAIL 5: insufficient latch must prevent sealing.');
assert(abs(l.pressurePa(end)-b.pressurePa(end))<1e-7, ...
    'FAIL 5: failed latch should reproduce no-repair pressure trace.');
assert(c.nArrived==q.nTiles && abs(c.effectiveArea(end)/p.area-0.40)<1e-10, ...
    'FAIL 5: partial contact scenario failed.');
assert(c.pressurePa(end)>b.pressurePa(end) && c.pressurePa(end)<a.pressurePa(end), ...
    'FAIL 5: partial pressure loss should be between repaired and unrepaired.');
fprintf('PASS 5: no actuation, weak field, weak latch, partial seal behave distinctly.\n');

% Choked-flow analytic no-seal solution after puncture:
% P(t)=P0*exp[-R*T/V * flowCoefficient * A * (t-t_puncture)]
closedForm=p.P0*exp(-(p.R*p.T/p.V)*a.flowCoefficient*p.area* ...
    max(0,b.t-p.tPuncture));
assert(max(abs(b.pressurePa-closedForm))<2, ...
    'FAIL 6: no-repair numerical solution diverges from analytic choked-flow result.');
fprintf('PASS 6: no-repair pressure matches analytic solution within 2 Pa.\n');
fprintf('\nALL SIX MAGSEAL HOUR 4 NUMERICAL CHECKS PASSED.\n');
fprintf('Physical airtightness, latch strength, actual coil field remain unvalidated.\n');
