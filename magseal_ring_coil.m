function [B,gradB] = magseal_ring_coil(r,p)
% Biot-Savart thin-loop approximation for local ACTUATION SCREENING.
% r is radial wall-plane distance from coil axis, m; coil lies p.coilOffset
% behind the wall. Returns B(x,0,z) [Tesla] and d|B|/dr [Tesla/m].
% Ignore core, winding thickness, magnetic saturation and spacecraft wiring.
h=p.fieldDifferenceStep;
B=loopAt(r,p);
Bp=loopAt(r+h,p); Bm=loopAt(max(r-h,0),p);
if r>=h
    gradB=(norm(Bp)-norm(Bm))/(2*h);
else
    gradB=(norm(Bp)-norm(B))/h;
end
end

function B = loopAt(r,p)
theta=(0:p.coilSegments-1)'*(2*pi/p.coilSegments);
a=p.coilRadius;
rx=r-a*cos(theta);
ry=-a*sin(theta);
rz=p.coilOffset*ones(size(theta));
dlX=-a*sin(theta)*(2*pi/p.coilSegments);
dlY= a*cos(theta)*(2*pi/p.coilSegments);
denom=(rx.^2+ry.^2+rz.^2).^(3/2);
% dl x R for dl=(dlX,dlY,0), R=(rx,ry,rz)
dBx= dlY.*rz ./denom;
dBy=-dlX.*rz ./denom;
dBz=(dlX.*ry-dlY.*rx)./denom;
mu0=4*pi*1e-7;
B=mu0*p.coilTurns*p.coilCurrent/(4*pi) * ...
  [sum(dBx),sum(dBy),sum(dBz)];
end
