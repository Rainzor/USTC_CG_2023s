function output = floater(v,f)
%基于floater权重保形的获得网格内部顶点的参数化坐标
%Input: 
%   v: mesh geometry 
%   f: mesh connectivity (list of triangle/polygon faces)
%Output:
%   parameterized coordinates in 2D circle
n_v = size(v, 1);
n_f = size(f, 1);
[B, ~] = findBoundary(v, f);
n_B = size(B, 2);


edge_i = reshape(f',1,[]);
edge_j = reshape(f(:,[2,3,1])',1,[]);%1->2->3

%length mat 边长矩阵
lenv = vecnorm(v(edge_i,:)-v(edge_j,:),2,2);
len_mat = sparse(edge_i,edge_j,lenv,n_v,n_v); 

%length
l = zeros(size(f));
l(:,1)=vecnorm(v(f(:,2),:)-v(f(:,3),:),2,2);
l(:,2)=vecnorm(v(f(:,1),:)-v(f(:,3),:),2,2);
l(:,3)=vecnorm(v(f(:,1),:)-v(f(:,2),:),2,2);
%cos
c = zeros(size(f));
c(:,1)=(l(:,2).^2+l(:,3).^2-l(:,1).^2)./(2*l(:,2).*l(:,3));
c(:,2)=(l(:,1).^2+l(:,3).^2-l(:,2).^2)./(2*l(:,1).*l(:,3));
c(:,3)=(l(:,1).^2+l(:,2).^2-l(:,3).^2)./(2*l(:,1).*l(:,2));
angle =  acos(c);

%angel_mat 角度矩阵
angle_mat = sparse(edge_i,edge_j,reshape(angle',1,[]));
angle_mat(B,:) = 0;
theta_sum = sum(angle_mat,2);
angle_mat = angle_mat./theta_sum*2*pi;%范围归一到0-2pi内

%vertex to face_id mat 顶点所在面坐标
vf_index_mat = sparse(f(:), repmat((1:n_f)', 3, 1), 1, n_v, n_f);
%weight_mat 重心坐标权重矩阵
adj_i = zeros(size(edge_i));
adj_j = zeros(size(edge_i));
weight_val = zeros(size(edge_i));
num_i = 0;
for i = 1:n_v
    if(any(ismember(B,i)))%在边界处就跳过
        continue
    end
    face_id = find(vf_index_mat(i,:));
    %找到顶点i的周围邻接点，按逆时针顺序排列,依次指向下一个
    vec_id = findBoundary(v,f(face_id,:));
    num = length(face_id);
    adj_i(num_i+1:num_i+num) = ones(1,num)*i;
    adj_j(num_i+1:num_i+num) = vec_id;
    pos = zeros(num,2);
    local_angle = zeros(num);
    pos(1,:) = [len_mat(i,vec_id(1)),0];
    local_angle(1) = 0;
    for j = 2:num
        local_angle(j) = local_angle(j-1) + angle_mat(i,vec_id(j-1));
        pos(j,:) = len_mat(i,vec_id(j))*[cos(local_angle(j)),sin(local_angle(j))];
    end
    %获取每个中心顶点邻居的权重
    weight_val(num_i+1:num_i+num) = getWeight(pos,local_angle);
    
    num_i = num_i+num;
end

%权重矩阵
weight_mat = sparse(adj_i(1:num_i),adj_j(1:num_i),weight_val(1:num_i),n_v,n_v);
sum_weight = full(sum(weight_mat,2));
sum_weight(B) = 1;
A_mat = -weight_mat + sparse(1:n_v,1:n_v,sum_weight,n_v,n_v);%这里系数矩阵中邻居的权重值应该取负
%向量
thetas = (1:n_B)*(2*pi/n_B);
dis_i = repmat(B,1,2);
dis_j = [ones(1,n_B),2*ones(1,n_B)];
dis_value = [cos(thetas),sin(thetas)];
dis_vec = sparse(dis_i,dis_j,dis_value,n_v,2);

output = A_mat\full(dis_vec);
end

function weight = getWeight(pos,angle)
    s = size(pos,1);
    w_mat = zeros(s,s);
    for i = 1:s
        anti_angle = angle(i)+pi;%点对称
        if(anti_angle>2*pi)
            anti_angle = anti_angle - 2*pi;
        end
        k = find(angle>anti_angle,1);%判断三角形的三个点
        if(isempty(k))
            k=1;j=s;
        else
            j = k-1;
        end
        A = [pos(i,:),1;pos(j,:),1;pos(k,:),1]';%求权重系数
        b = [0;0;1];
        uvw = A\b;
        w_mat([i,j,k],i) = uvw;
    end
    weight = sum(w_mat,2);
end
