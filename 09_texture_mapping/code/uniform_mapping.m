function output = uniform_mapping(v,f)
%基于均匀权重的 Laplace 方程获得网格内部顶点的参数化坐标
%Input: 
%   v: mesh geometry 
%   f: mesh connectivity (list of triangle/polygon faces)
%Output:
%   parameterized coordinates in 2D circle
[B,~] = findBoundary(v,f);
n_B = size(B,2);
n_v = size(v,1);

edge_i = reshape(f',1,[]);
edge_j = reshape(f(:,[2,3,1])',1,[]);%1->2->3
edges = [edge_i;edge_j];

[counts,~] = histcounts(edge_i,1:(n_v+1));
counts(B) = 1;%边界上的点可以直接赋值,在对角线上可以直接记为1

edges(:,any(edge_i==B')) = [];% remove boundary index
A_mat = sparse(edges(1,:),edges(2,:),-1,n_v,n_v)+ ...
        sparse(1:n_v,1:n_v,counts,n_v,n_v);

thetas = (1:n_B)*(2*pi/n_B);
dis_i = repmat(B,1,2);
dis_j = [ones(1,n_B),2*ones(1,n_B)];
dis_value = [cos(thetas),sin(thetas)];
dis_vec = sparse(dis_i,dis_j,dis_value,n_v,2);

output = A_mat\full(dis_vec);
end