function r = magseal_run_hour4_case(p,q,s)
% MAGSEAL HOUR 4 unified time-domain physical-system SURROGATE.
% Pressure -> detection -> field -> guided magnetic tile movement ->
% all-tile arrival -> geometric coverage + retention -> effective leak area -> pressure.
%
% NOT simulated: contact stress, material deformation, ionomer self-healing,
% fluid flow through inter-tile gaps, real coil fields, leakage measurements.
% Leakage after contact is explicitly an assumed residual-area fraction.
% Uses ideal-gas, well-mixed isothermal cabin; choked flow to vacuum.

assert(abs(p.Pext)<1e-12,'Hour 4 currently assumes Pext = 0 Pa (vacuum).');
assert(p.dt>0 && p.tEnd>p.tPuncture && p.area>0,'Invalid pressure parameters.');
assert(p.sensorDropPa>0 && p.sensorDropPa<p.P0,'Invalid sensor threshold.');
assert(q.nTiles>0 && numel(q.initialGap)==q.nTiles,'Invalid module count.');
assert(all(q.mass>0) && all(q.damping>=0),'Invalid module mass or damping.');
assert(q.gapRef>0 && q.coilRiseTime>0 && q.speedLimit>0,'Invalid magnetic parameters.');
assert(s.contactQuality>=0 && s.contactQuality<=1,'Contact quality must be in [0,1].');
assert(s.seatingDelay>=0 && s.latchCapacity>=0 && s.retentionSafetyFactor>=1, ...
    'Invalid seating delay or retention parameters.');

% Check radial overlap geometrically; this is not a membrane deformation model.
radialOverlap = (s.membraneDiameter-p.holeDiameter)/2;
coverageOK = radialOverlap>=s.requiredRadialOverlap;

N=q.nTiles;
t=(0:p.dt:p.tEnd)';
K=numel(t);
P=zeros(K,1); P(1)=p.P0;
command=zeros(K,1);
fieldFraction=zeros(K,1);
gap=zeros(K,N); gap(1,:)=q.initialGap(:)';
velocity=zeros(K,N);
magneticForce=zeros(K,N);
arrivals=nan(N,1);
effectiveArea=zeros(K,1);
leakMassFlow=zeros(K,1);
blockedFraction=zeros(K,1);
pressureLoad=zeros(K,1);
retentionDemand=zeros(K,1);
engaged=zeros(K,1);
tFirstAllArrived=NaN;
tEngaged=NaN;

% Fixed material/flow coefficient for choked pressure outflow to vacuum.
flowCoefficient=p.Cd*sqrt(p.gamma/(p.R*p.T))* ...
    (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));

for k=1:K
    % Sensor command is threshold-based and stays on (P only decreases).
    command(k)=double(P(k)<=p.P0-p.sensorDropPa);
    pressureLoad(k)=max(0,P(k)-p.Pext)*p.area;
    retentionDemand(k)=s.retentionSafetyFactor*pressureLoad(k);

    if isnan(tFirstAllArrived) && all(gap(k,:)<=1e-12)
        tFirstAllArrived=t(k);
    end
    seated=~isnan(tFirstAllArrived) && t(k)>=tFirstAllArrived+s.seatingDelay;
    retained=(s.latchCapacity>=retentionDemand(k));
    % The continuous cover engages only with adequate geometry AND load rating.
    engaged(k)=double(seated && coverageOK && retained && s.contactQuality>0);
    blockedFraction(k)=engaged(k)*s.contactQuality;

    if engaged(k)>0 && isnan(tEngaged), tEngaged=t(k); end
    punctured=double(t(k)>=p.tPuncture);
    effectiveArea(k)=p.area*punctured*(1-blockedFraction(k));
    leakMassFlow(k)=flowCoefficient*effectiveArea(k)*P(k);

    if k==K, break; end
    dt=t(k+1)-t(k);
    P(k+1)=max(p.Pext,P(k)-dt*(p.R*p.T/p.V)*leakMassFlow(k));
    fieldFraction(k+1)=fieldFraction(k) + ...
        (1-exp(-dt/q.coilRiseTime))*(command(k)-fieldFraction(k));

    for i=1:N
        if gap(k,i)<=0
            gap(k+1,i)=0;
            velocity(k+1,i)=0;
            continue;
        end
        grad=q.fieldScale*fieldFraction(k)*q.gradientRef* ...
            (q.gapRef/(q.gapRef+gap(k,i)))^q.gradientExponent;
        fmag=max(0,q.magneticMoment(i)*grad);
        magneticForce(k,i)=fmag;
        if velocity(k,i)==0 && fmag<=q.staticFriction(i)
            gap(k+1,i)=gap(k,i); velocity(k+1,i)=0;
            continue;
        end
        vDot=(fmag-q.kineticFriction(i)-q.damping(i)*velocity(k,i))/q.mass(i);
        vNew=min(q.speedLimit,max(0,velocity(k,i)+vDot*dt));
        xNew=max(0,gap(k,i)-vNew*dt);
        if xNew==0
            arrivals(i)=t(k+1);
            vNew=0;
        end
        gap(k+1,i)=xNew;
        velocity(k+1,i)=vNew;
    end
end
if K>1, magneticForce(end,:)=magneticForce(end-1,:); end
firstDetect=find(command>=0.5,1,'first');
if isempty(firstDetect), detectionTime=NaN; else,detectionTime=t(firstDetect);end

r.t=t;
r.pressurePa=P;
r.command=command;
r.fieldFraction=fieldFraction;
r.gap=gap;
r.velocity=velocity;
r.magneticForce=magneticForce;
r.arrivalTimes=arrivals;
r.nArrived=sum(isfinite(arrivals));
r.lastArrivalTime=tFirstAllArrived;
r.sealEngagementTime=tEngaged;
r.engaged=engaged;
r.blockedFraction=blockedFraction;
r.effectiveArea=effectiveArea;
r.leakMassFlow=leakMassFlow;
r.pressureLoad=pressureLoad;
r.retentionDemand=retentionDemand;
r.coverageOK=coverageOK;
r.radialOverlap=radialOverlap;
r.detectionTime=detectionTime;
r.flowCoefficient=flowCoefficient;
r.p=p;
r.q=q;
r.s=s;
end
