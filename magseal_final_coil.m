function [Fin,Fnormal,B] = magseal_final_coil(r,p,I)
% Axisymmetric circular-coil force at radius r in wall plane.
% Fin > 0 means radial attraction toward hole-centered coil axis.
% Normal >0 means attractive force AWAY from hull toward cabin-side coil.
% Induced-field magnetization and hysteresis are not solved.
if abs(I)<1e-12
    Fin=0; Fnormal=0; B=0; return
end
h=p.fieldStep; z=p.coilStandoff;
B=coilMagnitude(r,z,p,I);
% Use a true central difference in the simulated domain r >= 3 mm.
dBdr=(coilMagnitude(r+h,z,p,I)-coilMagnitude(r-h,z,p,I))/(2*h);
dBdz=(coilMagnitude(r,z+h,p,I)-coilMagnitude(r,z-h,p,I))/(2*h);
Fin=max(0,-p.carrierMoment*dBdr);
Fnormal=abs(p.carrierMoment*dBdz);
end

function mag=coilMagnitude(r,z,p,I)
% Exact field of a thin circular current loop via complete elliptic integrals.
mu0=4*pi*1e-7; a=p.coilRadius;
ap=(a+r)^2+z^2; bm=(a-r)^2+z^2;
k2=min(4*a*r/ap,1-1e-12);
[K,E]=ellipke(k2);
c=mu0*p.coilTurns*I/(2*pi*sqrt(ap));
Bz=c*(K+(a*a-r*r-z*z)*E/bm);
if abs(r)>1e-12
    Br=c*z/r*(-K+(a*a+r*r+z*z)*E/bm);
else
    Br=0;
end
mag=hypot(Bz,Br);
end
