function z = ARAP_interp(source,w, v2e_mat, A, S, theta)
%ARAP 插值算法
%input:
%   source,target为变换前后的边相邻
%   w:插值点
%   v2e_mat:从顶点坐标到边向量的变换矩阵
%   A:预分解的v2e_mat'*v2e_mat
%   T:位移矩阵
%   theta:旋转角度
    nt = size(theta,1);
    c = cos(w*theta); s = sin(w*theta);
    rotation_w = reshape([c, s, -s, c]', 2, 2, []);
    translation_w = (1-w)*reshape(kron(ones(1,nt),eye(2)),2,2,nt)+w*S;
    e_w = zeros(size(source));
    transform_w = zeros(2,2,nt);
    for i = 1:nt
        transform_w(:,:,i) = rotation_w(:,:,i)*translation_w(:,:,i);
        e_w(2*i-1:2*i,:)=source(2*i-1:2*i,:)*transform_w(:,:,i)';
    end
    b = full(v2e_mat'*e_w);
    z = A\b;
end