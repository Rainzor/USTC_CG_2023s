function output = harmon(v,f)
%基于cot权重保角的获得网格内部顶点的参数化坐标
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
weight_mat = sparse(edge_i,edge_j,cot_k,n_v,n_v)+...
                sparse(edge_j,edge_i,cot_k,n_v,n_v);
weight_diag = full(sum(weight_mat,2));
weight_mat(B,:) = 0;
weight_diag(B) = 1;

A_mat = sparse(1:n_v,1:n_v,weight_diag,n_v,n_v) - weight_mat;

thetas = (1:n_B)*(2*pi/n_B);
dis_i = repmat(B,1,2);
dis_j = [ones(1,n_B),2*ones(1,n_B)];
dis_value = [cos(thetas),sin(thetas)];
dis_vec = sparse(dis_i,dis_j,dis_value,n_v,2);

output = A_mat\full(dis_vec);
end