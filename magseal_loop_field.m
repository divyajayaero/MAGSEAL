function [Bx,By,Bz] = magseal_loop_field(X,Y,cx,cy,p,current)
% Finite circular AIR-CORE coil evaluated with discretized Biot-Savart.
% Coils are horizontal in plane z=-p.coilDepth; particles at z=0.
% Accuracy limited by finite segment count; NO iron core, hysteresis,
% wire size, coil heating, nearby metals, or spacecraft EMC modeling.
Bx=zeros(size(X)); By=Bx; Bz=Bx;
if current==0, return; end
R=p.coilRadius; Nseg=p.coilSegmentCount;
theta=((0:Nseg-1)+0.5)*(2*pi/Nseg);
dth=2*pi/Nseg;
for ii=1:Nseg
    c=cos(theta(ii)); s=sin(theta(ii));
    xcoil=cx+R*c; ycoil=cy+R*s;
    dlx=-R*s*dth; dly=R*c*dth;
    rx=X-xcoil; ry=Y-ycoil; rz=p.coilDepth;
    invR3=(rx.^2+ry.^2+rz^2).^(-1.5);
    k=p.mu0*p.coilTurns*current/(4*pi).*invR3;
    Bx=Bx+k.*dly*rz;
    By=By-k.*dlx*rz;
    Bz=Bz+k.*(dlx.*ry-dly.*rx);
end
end
