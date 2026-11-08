function run_magseal_exterior
% Run from MATLAB. Parameters shared with the executed Python reference.
% Conditional lumped model; all healing, delivery and strength inputs assumed.
root = fileparts(mfilename('fullpath'));
p = jsondecode(fileread(fullfile(root,'parameters.json')));
names = {'Untreated','Exterior only','Combined nominal assumptions', ...
    'Exterior does not heal','Exterior heals slowly','Exterior attachment fails'};
exterior = [false true true false true true];
menp = [false false true true true true];
% Recompute the retained original thin-loop field implementation.
radii = linspace(p.holeDiameter/2,p.rStart,501)';
forces = zeros(501,3);
for j=1:501
    [fr,fn] = magseal_final_coil(radii(j),p,1);
    forces(j,:) = [radii(j),fr,fn];
end
folder = fullfile(root,'matlab_results');
if ~exist(folder,'dir'), mkdir(folder); end
figure('Color','w','Position',[100 100 1200 750]);
tiledlayout(2,2);
ax1=nexttile; hold on; ylabel('Air leakage (mg/s)'); set(ax1,'YScale','log');
ax2=nexttile; hold on; ylabel('Cabin pressure lost (kPa)');
ax3=nexttile; hold on; ylabel('Retained polymer (microlitres)');
ax4=nexttile; hold on; ylabel('Nominal model state (%)');
summary=zeros(6,7);
for s=1:6
    q=p;
    if s==5, q.healingTau=60; end
    if s==6, q.exteriorCapacityN=1; end
    [x,arrival]=simulate_case(q,exterior(s),menp(s),forces);
    headers={'time_s','pressure_Pa','radius_m','current_A','coil_temperature_K', ...
        'exterior_open_area_fraction','retained_m3','used_m3','expelled_m3', ...
        'cure_fraction','leak_kg_s','bond_capacity_N','coil_energy_J'};
    writetable(array2table(x,'VariableNames',headers),fullfile(folder,sprintf('case_%d.csv',s)));
    leakForPlot=x(:,11)*1e6;
    leakForPlot(leakForPlot<=0)=NaN; % Zero has no finite logarithm.
    plot(ax1,x(:,1),leakForPlot,'DisplayName',names{s},'LineWidth',1.5);
    plot(ax2,x(:,1),(p.P0-x(:,2))/1000,'DisplayName',names{s});
    plot(ax3,x(:,1),x(:,7)*1e9,'DisplayName',names{s});
    if s==3
        plot(ax4,x(:,1),100*x(:,6),'DisplayName','Exterior open area');
        plot(ax4,x(:,1),100*x(:,10),'DisplayName','Assumed cure');
    end
    assert(max(abs(x(:,8)-x(:,7)-x(:,9)))<1e-16,'Inventory balance failed');
    summary(s,:)=[arrival,(p.P0-x(end,2))*p.Vcabin/(p.Rgas*p.Tgas)*1000, ...
        x(end,11)*1e6,x(end,7)*1e9,x(end,9)*1e9,max(x(:,5))-273.15,x(end,13)];
end
for ax=[ax1 ax2 ax3 ax4], grid(ax,'on'); xlabel(ax,'Time (s)'); end
legend(ax1,'Location','best','FontSize',8); legend(ax4,'Location','best');
yline(ax1,p.leakAcceptance*1e6,':','Screening threshold','HandleVisibility','off');
yline(ax3,pi*(p.holeDiameter/2)^2*p.hullThickness*1e9,':','Bore volume');
sgtitle('MAGSEAL exterior layer | 6 mm puncture | Assumed material behavior');
result=array2table(summary,'VariableNames',{'arrival_s','air_lost_g','final_leak_mg_s', ...
    'retained_uL','expelled_uL','peak_coil_C','coil_energy_J'});
result=addvars(result,names','Before',1,'NewVariableNames','scenario');
disp(result); writetable(result,fullfile(folder,'summary.csv'));
exportgraphics(gcf,fullfile(folder,'simulation_results.png'),'Resolution',170);
end

function [out,arrival]=simulate_case(p,exterior,menp,forces)
time=(0:round(p.tEnd/p.dt))'*p.dt;
out=zeros(numel(time),13);
area=pi*(p.holeDiameter/2)^2; target=area*p.hullThickness;
c=p.Cd*sqrt(p.gamma/(p.Rgas*p.Tgas))*(2/(p.gamma+1))^((p.gamma+1)/(2*(p.gamma-1)));
wireLength=p.coilTurns*2*pi*p.coilRadius;
wireArea=pi*(p.wireDiameter/2)^2;
resistance=p.copperResistivity*wireLength/wireArea;
heatCapacity=p.copperDensity*wireLength*wireArea*p.copperSpecificHeat;
pressure=p.P0; radius=p.rStart; temperature=p.ambientTemp;
retained=0; used=0; expelled=0; cure=0; energy=0;
detected=NaN; arrival=NaN; thermalFault=false;
supported=exterior && p.exteriorCapacityN>=p.safetyFactor*p.P0*area;
for k=1:numel(time)
    t=time(k);
    if t>=p.punctureTime && isnan(detected) && p.P0-pressure>=p.sensorDropPa
        detected=t;
    end
    current=0;
    if menp && isfinite(detected) && isnan(arrival) && ~thermalFault && t-detected<p.maxCoilOnTime
        current=p.coilCurrent*(1-exp(-(t-detected)/p.coilRampTau));
    end
    elapsed=max(0,t-p.punctureTime-p.healingDelay);
    opening=1;
    if supported
        opening=p.residualAreaFraction+(1-p.residualAreaFraction)*exp(-elapsed/p.healingTau);
    end
    if isfinite(arrival), cure=1-exp(-(t-arrival)/p.cureTau); end
    fill=min(1,retained/target);
    effectiveArea=area*min(1,opening*(1-fill*cure)+p.leakFloorAreaFraction*fill*cure);
    leak=0;
    if t>=p.punctureTime, leak=c*pressure*effectiveArea; end
    bond=p.finalBondShearStrength*pi*p.holeDiameter*p.hullThickness*fill*cure^2;
    out(k,:)=[t pressure radius current temperature opening retained used expelled cure leak bond energy];
    if k==numel(time), break; end
    dt=p.dt;
    if t>=p.punctureTime
        pressure=pressure*exp(-p.Rgas*p.Tgas/p.Vcabin*c*effectiveArea*dt);
    end
    power=current^2*resistance;
    equilibrium=p.ambientTemp+power*p.thermalResistance;
    temperature=equilibrium+(temperature-equilibrium)*exp(-dt/(heatCapacity*p.thermalResistance));
    thermalFault=thermalFault || temperature>=p.coilMaxTemp;
    energy=energy+power*dt;
    if current>0
        inward=interp1(forces(:,1),forces(:,2),radius)*current;
        normal=interp1(forces(:,1),forces(:,3),radius)*current;
        if inward>p.staticFriction+p.guideFrictionCoefficient*normal
            speed=min(p.speedLimit,(inward-p.kineticFriction-p.guideFrictionCoefficient*normal)/p.motionDamping);
            radius=max(p.holeDiameter/2,radius-speed*dt);
            if radius<=p.holeDiameter/2, arrival=t+dt; end
        end
    end
    if isfinite(arrival) && t>=arrival
        feed=0;
        if t-arrival<p.workingLife
            feed=min([p.feedRate*dt,max(0,p.inventory-used),max(0,target-retained)]);
        end
        used=used+feed;
        apertureRadius=p.holeDiameter/2*sqrt(opening);
        path=p.hullThickness+double(supported)*p.exteriorThickness;
        qLoss=pi*apertureRadius^4*out(k,2)/(8*p.gelViscosity*path)*(1-cure)^3;
        loss=min(retained+feed,qLoss*dt);
        expelled=expelled+loss;
        retained=retained+feed-loss;
    end
end
end
