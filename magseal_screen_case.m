function z = magseal_screen_case(p)
% Engineering screening model, NOT laboratory verification or CFD.
% 1) pressure-detected damage; 2) magnetic elastomer head advances on guide;
% 3) guided actuator delivers captive polymer sealant into hole;
% 4) assumed cured polymer limits gas escape. Includes failure cases.
A=pi*(p.dHole/2)^2;
Vbore=A*p.tHull;
Vhead=pi*(p.headDiameter/2)^2*p.headThickness;
Vfill=Vbore+Vhead;
Vstore=pi*(p.reservoirOuterRadius^2-p.reservoirInnerRadius^2)* ...
    p.reservoirThickness*p.recoverableFraction;
VdispNeeded=Vfill/p.deliveryEfficiency;
Fpressure=(p.P0-p.Pext)*A;
Ftarget=Fpressure*p.requiredSafetyFactor;
latchOK = p.latchCapacity >= Ftarget;
inventoryOK = Vstore >= VdispNeeded;

% One centered coil, illustrated at far and near positions. Multiple
% local coils/relay would be required for distant modules.
[~,gNear]=magseal_ring_coil(p.petalStartRadius,p);
[~,gFar]=magseal_ring_coil(p.farRadiusForComparison,p);
[~,gPump]=magseal_ring_coil(p.pumpActuatorRadius,p);
Fnear=max(0,-gNear)*p.effectiveMoment;
Ffar=max(0,-gFar)*p.effectiveMoment;
Fpump=max(0,-gPump)*p.effectiveMoment;
magneticHeadCanStart=Fnear>p.staticFriction;

% Independent local actuator acts on pump piston after head is seated.
Fpiston=max(0,Fpump-p.staticFriction)*p.mechanicalPumpEfficiency;
fluidPressure=Fpiston/(pi*p.pumpPlungerRadius^2);
% Poiseuille law valid for LOW-Reynolds, Newtonian no-yield-stress fluid.
Q=pi*p.channelRadius^4*fluidPressure/(8*p.gelViscosity*p.channelLength);

% Magnetic movement of the head using actual spatial coil gradient.
% Explicit Euler, fine timestep for stability (not derived from Simulink).
dtm=0.001;
% Tabulate field gradient to avoid expensive coil integration each step.
rGrid=linspace(p.petalStopRadius,p.petalStartRadius,180);
gGrid=zeros(size(rGrid));
for gidx=1:numel(rGrid)
    [~,gTmp]=magseal_ring_coil(rGrid(gidx),p);
    gGrid(gidx)=max(0,-gTmp);
end
r=p.petalStartRadius; v=0; tMove=0; moveSuccess=false;
if magneticHeadCanStart && p.localizationSuccessful
  for j=1:10000
    coilFactor=min(1,tMove/max(p.coilRiseTime,dtm));
    G=interp1(rGrid,gGrid,r,'linear','extrap');
    F=G*p.effectiveMoment*coilFactor;
    if v<1e-10 && F<=p.staticFriction
      v=0;
    else
      accel=(F-p.kineticFriction-p.damping*v)/p.petalMass;
      v=max(0,min(p.maxPetalSpeed,v+dtm*accel));
      r=max(p.petalStopRadius,r-dtm*v);
    end
    tMove=tMove+dtm;
    if r<=p.petalStopRadius+1e-12
      moveSuccess=true;break;
    end
  end
end

% Coil heating: adiabatic upper-bound. Extreme temps need thermal design.
wireL=2*pi*p.coilRadius*p.coilTurns;
wireA=pi*p.wireRadius^2;
Rcoil=p.copperResistivity*wireL/wireA;
coilPower=p.coilCurrent^2*Rcoil;
coilHeatCapacity=wireL*wireA*p.copperDensity*p.copperSpecificHeat;
coilOnTime=tMove;
if Q>0 && p.enableFillingGel && inventoryOK
   coilOnTime=coilOnTime+VdispNeeded/Q;
end
adiabaticDeltaT=coilPower*coilOnTime/coilHeatCapacity;

% Time simulation: distinguishes a pressure-reducing temporary head and a
% permanent cured plug. Both leakage factors are explicit untested inputs.
t=0:p.dt:p.tEnd; n=numel(t);
pressure=zeros(1,n);pressure(1)=p.P0;
leak=zeros(1,n);remaining=zeros(1,n);stage=zeros(1,n);
pressureArea=zeros(1,n); pressureArea(1)=0;
filled=0; detTime=NaN;headTime=NaN;fillTime=NaN;curedTime=NaN;
for k=1:n-1
  ti=t(k); P=pressure(k);
  if ti>=p.tPuncture && isnan(detTime) && P<=p.P0-p.detectDrop
      detTime=ti;
  end
  headEngaged = p.enableElastomerHead && latchOK && moveSuccess && ...
      ~isnan(detTime) && ti>=detTime+p.controllerDelay+tMove;
  if headEngaged && isnan(headTime),headTime=ti;end
  % Gel delivery starts only after a head captures and retains it.
  delivering=headEngaged && p.enableFillingGel && inventoryOK && ...
      p.localizationSuccessful && Q>0 && (filled<Vfill);
  if delivering
      filled=min(Vfill,filled+Q*p.deliveryEfficiency*p.dt);
  end
  if filled>=Vfill*(1-1e-10) && isnan(fillTime),fillTime=ti+p.dt;end
  cured=p.enableCuring && ~isnan(fillTime) && ti>=fillTime+p.cureTime && latchOK;
  if cured && isnan(curedTime),curedTime=ti;end

  if ti<p.tPuncture
     frac=0;stage(k)=0;
  elseif cured
     frac=p.residualOpenAfterCure;stage(k)=5;
  elseif headEngaged
     frac=p.residualOpenBeforeCure;
     if isnan(fillTime),stage(k)=3;else,stage(k)=4;end
  elseif ~isnan(detTime)
     frac=1;stage(k)=2;
  else
     frac=1;stage(k)=1;
  end
  pressureArea(k)=frac*A;
  if frac>0
    critical=(2/(p.gamma+1))^(p.gamma/(p.gamma-1));
    pratio=p.Pext/max(P,1);
    if pratio<=critical
      mdot=p.Cd*pressureArea(k)*P*sqrt(p.gamma/(p.R*p.T))* ...
           (2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
    else
      mdot=p.Cd*pressureArea(k)*P*sqrt(max(0,(2*p.gamma)/(p.R*p.T*(p.gamma-1))* ...
          (pratio^(2/p.gamma)-pratio^((p.gamma+1)/p.gamma))));
    end
  else
    mdot=0;
  end
  leak(k)=mdot;
  pressure(k+1)=max(p.Pext,P-p.dt*(p.R*p.T/p.Vcabin)*mdot);
  remaining(k)=Vfill-filled;
end
leak(end)=leak(end-1);stage(end)=stage(end-1);
remaining(end)=Vfill-filled;pressureArea(end)=pressureArea(end-1);

z=p;
z.time=t;z.pressure=pressure;z.massLeak=leak;z.stage=stage;
z.effectiveArea=pressureArea;z.remainingVolume=remaining;
z.detectionTime=detTime;z.headTime=headTime;z.filledTime=fillTime;z.curedTime=curedTime;
z.dHole_mm=p.dHole*1e3;
z.pressureForce_N=Fpressure;z.requiredRetention_N=Ftarget;
z.fillVolume_uL=Vfill*1e9;z.availableVolume_uL=Vstore*1e9;
z.dispensedRequired_uL=VdispNeeded*1e9;
z.inventoryOK=inventoryOK;z.latchOK=latchOK;
z.forceNear_mN=Fnear*1e3;z.forceFar_mN=Ffar*1e3;
z.forcePump_mN=Fpump*1e3;
z.gradientNear_Tpm=max(0,-gNear);z.gradientFar_Tpm=max(0,-gFar);
z.canMoveHead=moveSuccess;z.headMotionTime_s=tMove;
z.gelFlow_uLps=Q*1e9;z.pressurePump_Pa=fluidPressure;
z.coilPower_W=coilPower;z.coilOnTime_s=coilOnTime;
z.coilAdiabaticRise_K=adiabaticDeltaT;
z.needsThermalDesign=coilOnTime>p.maxMagnetRunSeconds || ...
    adiabaticDeltaT>p.maxAdiabaticRise_K;
z.lowLeakFinal=~isnan(curedTime) && leak(end)<=p.acceptableLeak_kgps;
end
