[x,t] = readObj('elephant_s');
y = readObj('elephant_t');
nv = size(x,1);
nt = size(t,1);
%绘图
amd = figure('position', [10 50 1000, 700]); subplot(121); drawmesh(t, x);
% subplot(133); drawmesh(t, y);
subplot(122); h=drawmesh(t, x);
filename= "ARAP.gif";
%保留2D变量
x = x(:,[1,2]);
y = y(:,[1,2]);
x_start = x(1,:);
y_start = y(1,:);


% 将所有三角形的边存储在edge
edge_i = reshape(t',1,[]);
edge_j = reshape(t(:,[2,3,1])',1,[]);%1->2->3
edges = [edge_i;edge_j];

e2t_v = repmat(1:nt,3,1);
e2t_v = reshape(e2t_v,1,[]);
e2t_idx = full(sparse(edges(1,:),edges(2,:),e2t_v,nv,nt));%通过有向边找所在面


%构造顶点与边的变换矩阵
weight = ones(1,nt);
v2e_i = reshape(repmat(1:2*nt,2,1),1,[]);
v2e_j = reshape([[t(:,1),t(:,2)]';[t(:,2),t(:,3)]'],1,[]);
v2e_v = repmat(reshape([weight;-weight],1,[]),1,2);
v2e_value = sparse(v2e_i,v2e_j,v2e_v,nt*2,nv);
A = decomposition(v2e_value'*v2e_value);%预分解

edge_sor = full(v2e_value*x);
edge_tar = full(v2e_value*y);


%构造图形变形矩阵
S = zeros(2,2,nt);
R_theta = zeros(nt,1);
for i = 1:nt
    source = [edge_sor(2*i-1,:);edge_sor(2*i,:)];
    target = [edge_tar(2*i-1,:);edge_tar(2*i,:)];
    transform_mat = (source\target)';
    [U,S1,V] = svd(transform_mat);
    R = U*V';
    S(:,:,i) = V*S1*V';
    R_theta(i) = atan2(R(2,1),R(1,1));
end

%处理旋转不一致问题
R_theta = rotationConsist(e2t_idx,t,R_theta);


%插值绘图
for w = [0:0.01:1,1:-0.01:0.01]
% for w = 0:0.01:0.5
    %% placeholder: linear interpolating the vertex positions
    % z = (1-w)*x + w*y;
    
    %% TODO: finish the ARAP interpolation function
    z = ARAP_interp(edge_sor,w,v2e_value, A, S, R_theta);
    x_w = (1-w)*x_start+w*y_start;
    delta = x_w-z(1,:);
    z = z + repmat(delta,nv,1);
    
    %% draw the result
    set(h,'vertices',z);
    drawnow; 

    % frame = getframe(amd);
    % im = frame2im(frame); 
    % [imind,cm] = rgb2ind(im,256);
    % if w==0
    %     imwrite(imind,cm,filename,'gif','WriteMode','overwrite', 'Loopcount',inf);
    % else
    %     imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',0.02);
    % end
end



function h = drawmesh(t, x)
    h = trimesh(t, x(:,1), x(:,2), x(:,1), 'facecolor', 'interp', 'edgecolor', 'k');
    axis equal;
    xlim([0,1.3]);
    ylim([0,1.3]);
    axis off; view(2);
end