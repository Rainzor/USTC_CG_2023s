xv = [0.5;0.2;1.0;0;0.8;0.5];
yv = [1.0;0.1;0.7;0.7;0.1;1];
xq = [0.1;0.5;0.9;0.2;0.4;0.5;0.5;0.9;0.6;0.8;0.7;0.2];
yq = [0.4;0.6;0.9;0.7;0.3;0.8;0.2;0.4;0.4;0.6;0.2;0.6];
[in,on] = inpolygon(xq,yq,xv,yv);
figure

plot(xv,yv) % polygon

hold on
plot(xq(in&~on),yq(in&~on),'r+') % points strictly inside
plot(xq(on),yq(on),'k*') % points on edge
plot(xq(~in),yq(~in),'bo') % points outside
hold off