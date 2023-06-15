function output = cotangent(v,f)
%基于cot权重的 Laplace 矩阵
%Input: 
%   v: mesh geometry 
%   f: mesh connectivity (list of triangle)
%Output:
%   Cotangent Weight Matrix
nv = size(v,1);

edge_i = reshape(f',1,[]);
edge_j = reshape(f(:,[2,3,1])',1,[]);%1->2->3
%计算每条边长
l(:,1) = vecnorm(v(f(:,1),:)-v(f(:,2),:),2,2);
l(:,2) = vecnorm(v(f(:,2),:)-v(f(:,3),:),2,2);
l(:,3) = vecnorm(v(f(:,3),:)-v(f(:,1),:),2,2);
%计算三角形ijk中k的cos，cot值
cos_k = zeros(size(f));
cos_k(:,1) = (l(:,2).^2+l(:,3).^2-l(:,1).^2)./(2*l(:,2).*l(:,3));
cos_k(:,2) = (l(:,3).^2+l(:,1).^2-l(:,2).^2)./(2*l(:,3).*l(:,1));
cos_k(:,3) = (l(:,1).^2+l(:,2).^2-l(:,3).^2)./(2*l(:,1).*l(:,2));
cot_k = cos_k./sqrt(1-cos_k.^2);

cot_k = reshape(cot_k',1,[]);
%计算ij的权重函数
weight_mat = sparse(edge_i,edge_j,cot_k,nv,nv)+...
                sparse(edge_j,edge_i,cot_k,nv,nv);
weight_diag = full(sum(weight_mat,2));

output = sparse(1:nv,1:nv,weight_diag,nv,nv) - weight_mat;


end