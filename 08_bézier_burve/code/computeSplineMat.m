function spline_mat  = computeSplineMat(np)
%input: 控制点个数np
%output: 样条辅助点转换矩阵
    %C0连续
    n = (np-1)*3+1;
    index_unity = (1:3:n)';
    val_unity = ones(np,1);
    index_x = (1:np)';
    n_index = np;
    %C1连续
    n_C1 = 3*(np-2);
    index_C1 = zeros(n_C1,1);
    val_C1 = zeros(n_C1,1);
    coff_C1 = [1,-2,1];
    for i=1:3
        index_C1(i:3:n_C1) = i+2:3:n-2;
        val_C1(i:3:n_C1) = coff_C1(i);
    end
    temp = repmat(1+n_index:np-2+n_index,3,1);
    index_x = [index_x;reshape(temp,[],1)];
    n_index = n_index+(np-2) ;
    %C2连续
    n_C2 = 5*(np-2);
    index_C2 = zeros(n_C2,1);
    val_C2 = zeros(n_C2,1);
    coff_C2 = [-1,2,0,-2,1];
    for i=1:5
        index_C2(i:5:n_C2) = i+1:3:n-6+i;
        val_C2(i:5:n_C2) = coff_C2(i);
    end
    index_C2(3:5:n_C2) = [];
    val_C2(3:5:n_C2) = [];
    n_C2 = 4*(np-2);
    temp = repmat(1+n_index:np-2+n_index,4,1);
    index_x = [index_x;reshape(temp,[],1)];
    n_index = n_index + (np-2);
    %边界条件
    n_bound = 6;
    index_bound = [1,2,3,n-2,n-1,n]';
    val_bound = [1,-2,1,1,-2,1]';
    temp = repmat(1+n_index:2+n_index,3,1);
    index_x = [index_x;reshape(temp,[],1)];
    n_index = n_index + 2;
    %构造稀疏矩阵
    index_y = [index_unity;index_C1;index_C2;index_bound];
    val = [val_unity;val_C1;val_C2;val_bound];
    spline_mat = sparse(index_x,index_y,val,n,n);
    %预分解
    spline_mat = decomposition(spline_mat);
end