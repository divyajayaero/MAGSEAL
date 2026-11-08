function results = magseal_simulate_tiles(t,command,q)
% Simulate 12 independent guided magnetic repair modules after detection.
% Motion: m*dv/dt = magneticForce - friction - damping*v.
% Magnetic dipole aligned with local field gradient: F ~= moment * dB/dr.
% Gradient decay is an ASSUMED surrogate, not Maxwell/FEM prediction.
% Simulates arrival only; does NOT compute sealing or air leak reduction.

t = t(:); command = double(command(:));
assert(numel(t)==numel(command),'Time and command lengths must match.');
assert(all(diff(t)>0),'Time must increase strictly.');
N = q.nTiles; steps = numel(t);
assert(numel(q.initialGap)==N,'Tile count and initialGap size disagree.');
assert(all(q.mass>0) && all(q.damping>=0),'Invalid mass/damping.');
assert(all(q.initialGap>=0),'Gap must be nonnegative.');
assert(q.coilRiseTime>0 && q.gapRef>0,'Time constant/gapRef must be positive.');

gap = zeros(steps,N); velocity=zeros(steps,N); force=zeros(steps,N);
gap(1,:) = q.initialGap(:)';
fieldFraction=zeros(steps,1);
arrivalTime=nan(N,1);
for k=1:steps-1
    dt=t(k+1)-t(k);
    fieldFraction(k+1) = fieldFraction(k) + (1-exp(-dt/q.coilRiseTime)) * ...
         (min(1,max(0,command(k)))-fieldFraction(k));
    for i=1:N
        if gap(k,i)<=0
            gap(k+1,i)=0; velocity(k+1,i)=0;
            continue;
        end
        grad=q.fieldScale*fieldFraction(k)*q.gradientRef * ...
            (q.gapRef/(q.gapRef+gap(k,i)))^q.gradientExponent;
        fmag=max(0,q.magneticMoment(i)*grad);
        force(k,i)=fmag;
        % Correct static friction behavior: no motion before F > F_static.
        if velocity(k,i)==0 && fmag<=q.staticFriction(i)
            gap(k+1,i)=gap(k,i); velocity(k+1,i)=0;
            continue;
        end
        vDot=(fmag-q.kineticFriction(i)-q.damping(i)*velocity(k,i))/q.mass(i);
        vNew=min(q.speedLimit,max(0,velocity(k,i)+vDot*dt));
        xNew=max(0,gap(k,i)-vNew*dt);
        if xNew==0
            arrivalTime(i)=t(k+1);
            vNew=0;
        end
        gap(k+1,i)=xNew;
        velocity(k+1,i)=vNew;
    end
end
if steps>1,force(end,:)=force(end-1,:);end
results.t=t;
results.command=command;
results.fieldFraction=fieldFraction;
results.gap=gap;
results.velocity=velocity;
results.magneticForce=force;
results.arrivalTime=arrivalTime;
results.reached=~isnan(arrivalTime);
results.numArrived=sum(results.reached);
end
