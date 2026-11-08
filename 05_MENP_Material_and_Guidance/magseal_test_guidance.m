function out = magseal_test_guidance(p,makePlots)
% TEST 2: actual air-core coil Biot-Savart field map + magnetophoretic
% upper-bound drift for MENPs in a water-viscosity confined MOBILE carrier.
% Two coil geometries: an idealized center coil, and four surrounding coils.
% Does NOT model the magnetoelectric electrical coupling or magnetic M(H).
if nargin<2,makePlots=true;end
v=linspace(-p.gridExtent,p.gridExtent,p.nGrid);
[X,Y]=meshgrid(v,v);
config(1).name='Idealized coil at puncture';
config(1).locations=[0 0];
a=p.surroundingCoilOffset;
config(2).name='4 surrounding coils, equal polarity';
config(2).locations=[a 0;-a 0;0 a;0 -a];
rm=sqrt(X.^2+Y.^2);
mask=(rm>=p.dHole/2+0.0005)&(rm<=0.010);
volume=(pi/6)*p.particleDiameter^3;
particleMass=volume*p.rhoMENP;
mparticle=particleMass*p.MrMass*p.momentAlignment;
mparticleSat=particleMass*p.MsMass*p.momentAlignment;
FdragPerSpeed=3*pi*p.muCarrier*p.particleDiameter;
kB=1.380649e-23;
D=kB*p.T/FdragPerSpeed;

for k=1:2
    Bx=zeros(size(X));By=Bx;Bz=Bx;
    for j=1:size(config(k).locations,1)
        pos=config(k).locations(j,:);
        [tx,ty,tz]=magseal_loop_field(X,Y,pos(1),pos(2),p,p.coilCurrent);
        Bx=Bx+tx;By=By+ty;Bz=Bz+tz;
    end
    Bmag=sqrt(Bx.^2+By.^2+Bz.^2);
    [dBx,dBy]=gradient(Bmag,v,v); % MATLAB: first output dB/dx, second dB/dy
    G=sqrt(dBx.^2+dBy.^2);
    inward=-(X.*dBx+Y.*dBy)./max(rm,eps);
    cosine=inward./max(G,eps);
    fractionInward=mean(cosine(mask)>0.1);
    sx=p.sourceParticlePos(1);sy=p.sourceParticlePos(2);
    Gx0=interp2(X,Y,dBx,sx,sy,'linear',0);
    Gy0=interp2(X,Y,dBy,sx,sy,'linear',0);
    gIn0=-(sx*Gx0+sy*Gy0)/hypot(sx,sy);
    speedIn0=mparticle*gIn0/FdragPerSpeed;
    % Track deterministic 2D path of one mobile particle for 300 seconds.
    n=round(p.mobilityTime/p.dt)+1;
    t=(0:n-1)'*p.dt;
    path=zeros(n,2); path(1,:)=[sx,sy];
    for it=2:n
        px=path(it-1,1);py=path(it-1,2);
        gx=interp2(X,Y,dBx,px,py,'linear',0);
        gy=interp2(X,Y,dBy,px,py,'linear',0);
        vxy=mparticle*[gx gy]/FdragPerSpeed;
        next=path(it-1,:)+p.dt*vxy;
        if norm(next)<=p.dHole/2
            path(it:end,:)=next;break
        end
        path(it,:)=next;
    end
    config(k).Bmag=Bmag;
    config(k).gradX=dBx;config(k).gradY=dBy;
    config(k).gradMag=G;
    config(k).fractionInward=fractionInward;
    config(k).startGradInward=gIn0;
    config(k).startSpeedInward=speedIn0;
    config(k).path=path;
    config(k).time=t;
    config(k).inwardDisplacement= ...
        (norm(path(1,:))-norm(path(end,:)));
end
% Constant-gradient requirement just for 8mm->3mm in 300s in mobile fluid.
travel=hypot(p.sourceParticlePos(1),p.sourceParticlePos(2))-p.dHole/2;
requiredG=travel*FdragPerSpeed/(mparticle*p.mobilityTime);
requiredSat=travel*FdragPerSpeed/(mparticleSat*p.mobilityTime);
rmsBrownian=sqrt(4*D*p.mobilityTime); % planar displacement RMS
fprintf('\n=== TEST 2: ACTUAL AIR-CORE COIL FIELDS + MENP DRIFT ===\n');
fprintf('Coil R=%.1f mm, N=%d turns, I=%.2f A, depth=%.1f mm\n', ...
    p.coilRadius*1e3,p.coilTurns,p.coilCurrent,p.coilDepth*1e3);
fprintf('Single %.0f-nm particle effective remanent dipole %.3g A*m^2\n', ...
    p.particleDiameter*1e9,mparticle);
for k=1:2
    fprintf('%s: %.1f%% sampled locations point inward; radial G at 8mm: %.3f T/m\n', ...
        config(k).name,100*config(k).fractionInward,config(k).startGradInward);
    fprintf('  Initial inward drift: %.4f um/s; progress over %.0f s: %.3f um\n', ...
        config(k).startSpeedInward*1e6,p.mobilityTime,...
        config(k).inwardDisplacement*1e6);
end
fprintf('Required CONSTANT inward gradient for 5-mm travel in 300s:\n');
fprintf('  Remanence estimate %.0f T/m; saturation upper proxy %.0f T/m\n', ...
    requiredG,requiredSat);
fprintf('Brownian planar RMS in %.0fs (not directed): %.1f um\n', ...
    p.mobilityTime,rmsBrownian*1e6);
fprintf('If particles are chemically bonded/immobilized: DRIFT = ZERO.\n');
if makePlots
    figure('Name','MAGSEAL test 2 - coil guidance','Color','w');
    tiledlayout(1,2);
    for k=1:2
        nexttile;
        imagesc(v*1e3,v*1e3,config(k).Bmag*1e3);axis image xy;hold on;
        ds=8;
        gx=config(k).gradX;gy=config(k).gradY;
        den=sqrt(gx.^2+gy.^2)+eps;
        quiver(X(1:ds:end,1:ds:end)*1e3,Y(1:ds:end,1:ds:end)*1e3,...
            gx(1:ds:end,1:ds:end)./den(1:ds:end,1:ds:end), ...
            gy(1:ds:end,1:ds:end)./den(1:ds:end,1:ds:end),.6,'w');
        ang=linspace(0,2*pi,200);
        plot(p.dHole*500*cos(ang),p.dHole*500*sin(ang),'r-','LineWidth',1.8);
        plot(config(k).locations(:,1)*1e3,config(k).locations(:,2)*1e3, ...
            'wo','MarkerFaceColor','k','MarkerSize',5);
        plot(config(k).path(:,1)*1e3,config(k).path(:,2)*1e3,'c','LineWidth',2);
        plot(p.sourceParticlePos(1)*1e3,p.sourceParticlePos(2)*1e3,'c*');
        xlabel('Wall x (mm)');ylabel('Wall y (mm)');
        title(sprintf('%s | inward %.0f%%',config(k).name,100*config(k).fractionInward));
        colorbar;
    end
    sgtitle('Air-core | |B| mT; arrows show gradient toward stronger field, NOT measured paths');
    figure('Name','MAGSEAL test 2 - transport limits','Color','w');
    tiledlayout(2,1);
    nexttile;
    vals=1e6*[config.inwardDisplacement];
    bar(vals);xticks(1:2);xticklabels({'Coil centered','4 surround'});
    ylabel('Net inward displacement (um), 300 s');
    title('100-nm MENP in a water-like carrier; bonded film would not move');grid on;
    nexttile;
    bar([requiredG requiredSat]);
    set(gca,'XTickLabel',{'Remanent proxy','Saturation proxy'});
    ylabel('Required constant gradient (T/m)');
    title('Target: 5 mm directed travel in 300 s, water-like carrier');grid on;
end
out=struct('configurations',config,'particleDipoleAm2',mparticle,...
    'requiredGradientRemanenceTm',requiredG, ...
    'requiredGradientSaturationTm',requiredSat, ...
    'brownianRMSm',rmsBrownian,'particleMassKg',particleMass);
end
