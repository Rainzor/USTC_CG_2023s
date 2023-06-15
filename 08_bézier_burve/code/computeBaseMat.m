function base_mat = computeBaseMat(nt,np)
%输入: 时间序列点数nt,控制点个数np
%输出: Bernstein 基函数矩阵
    base = zeros(1,np);
    for i=1:np
        base(i)=nchoosek(np-1, i-1);
    end
    base_mat = zeros(nt,np);    
    for i = 1:nt
        t = (i-1)/nt;
        base_mat(i,:) = (1-t).^(np-1:-1:0).*((t).^(0:1:np-1)).*base;
    end
end
