%三维网格参数化
[v,f,~,~] = readObj('cathead.obj',false);
drawmesh(f, v);
figure
v_uniform = uniform(v,f);

% v_uniform = v_uniform./2;
% v_uniform = v_uniform+[0.5,0.5];
drawmesh(f,v_uniform);
set(gcf,'name','uniform');
% figure
% v_harmonic = harmon(v,f);
% drawmesh(f,v_harmonic);
% set(gcf,'name','harmonic');
% figure
% v_floater = floater(v,f);
% drawmesh(f,v_floater);
% set(gcf,'name','flaoter');

