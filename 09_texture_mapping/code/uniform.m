function output = uniform(v,f)
%基于均匀权重的 Laplace 矩阵
%Input: 
%   v: mesh geometry 
%   f: mesh connectivity (list of triangle)
%Output:
%   Uniform Weight Matrix
nv = size(v,1);
edge_i = reshape(f',1,[]);
edge_j = reshape(f(:,[2,3,1])',1,[]);%1->2->3
edges = [edge_i;edge_j];

w_mat = sparse(edges(1,:),edges(2,:),1,nv,nv);
w_mat = w_mat + transpose(w_mat);w_mat(w_mat ~= 0) = 1;

count = full(sum(w_mat,2));
output = sparse(1:nv,1:nv,count,nv,nv)-w_mat;


end