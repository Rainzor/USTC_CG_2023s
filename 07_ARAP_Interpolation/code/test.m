
[x,t] = readObj('elephant_s');
y = readObj('elephant_t');
nv = size(x,1);
nt = size(t,1);
[B,~] = findBoundary(x,t);%找边
nB = size(B,2);
%绘图
%保留2D变量
x = x(:,[1,2]);
y = y(:,[1,2]);
x_start = x(1,:);
y_start = y(1,:);


% 将所有三角形的边存储在edge
edge_i = reshape(t',1,[]);
edge_j = reshape(t(:,[2,3,1])',1,[]);%1->2->3
edges = [edge_i;edge_j];

e2t_value = repmat(1:nt,3,1);
e2t_value = reshape(e2t_value,1,[]);
e2t = full(sparse(edges(1,:),edges(2,:),e2t_value,nv,nt));%通过有向边找所在面



%构造顶点与边的变换矩阵
weight = ones(1,nt);
ve_i = reshape(repmat(1:2*nt,2,1),1,[]);
ve_j = reshape([[t(:,1),t(:,2)]';[t(:,2),t(:,3)]'],1,[]);
ve_value = repmat(reshape([weight;-weight],1,[]),1,2);
ve_spa = sparse(ve_i,ve_j,ve_value,nt*2,nv);
A = decomposition(ve_spa'*ve_spa);%预分解

edge_sor = full(ve_spa*x);
edge_tar = full(ve_spa*y);


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


    queue = 1;
    nt = size(t,1);
    waitlist = ones(nt,1);
    waitlist(1) = 0;
    u = zeros(nt,2);
    theta1 = R_theta;
    while queue
        head = queue(1);
        t_head = t(head,:);
        u(head,:) = mean(x(t_head,:));
        t_adj = zeros(1,3);
        %寻找相邻三角形，
        %如果边1->2所在三角形为A,
        %那么2->1所在三角形B，与A相邻
        t_adj(1) = e2t(t_head(2),t_head(1));
        t_adj(2) = e2t(t_head(3),t_head(2));
        t_adj(3) = e2t(t_head(1),t_head(3));
        t_adj = t_adj(t_adj ~=0);
        t_adj(waitlist(t_adj)==0) = [];%已经处理过的三角形不再重复处理
        for l = t_adj'
            while R_theta(head) - R_theta(l) > pi
                R_theta(l) = R_theta(l)+2*pi;
            end
            while R_theta(head) - R_theta(l) < -pi
                R_theta(l) = R_theta(l)-2*pi;
            end
        end
        waitlist(t_adj) = 0;
        queue = [queue,t_adj];
        queue(1) = [];
    end
theta2= R_theta;
Z = theta2;
X = u(:,1);
Y = u(:,2);
Z_normalized = (Z - min(Z)) / (max(Z) - min(Z));
% 将归一化后的Z值映射到颜色映射中
cmap = colormap; % 使用当前的颜色映射（默认为'parula'）
color_indices = ceil(Z_normalized * (size(cmap, 1) - 1)) + 1;
colors = cmap(color_indices, :);

% 使用scatter函数绘制平面视图，颜色表示能量大小
scatter(X, Y, 50, colors, 'filled'); % 50为散点大小，可以根据需要调整

% 设置坐标轴标签和标题
xlabel('X-axis');
ylabel('Y-axis');
title('rotation consistency');
legend("\theta");

% 添加颜色条
caxis([min(Z), max(Z)]); % 设置颜色轴的范围
colorbar;


