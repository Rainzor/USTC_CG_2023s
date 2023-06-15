feature('DefaultCharacterSet', 'GB2312');
nv = size(x, 1);
nf = size(t, 1);
nP = size(P2PVtxIds,1);
if(isCot)
    Laplace_mat = cotangent(x,t);
else
    Laplace_mat = uniform(x,t);
end
delta = Laplace_mat*x;


lambda = 1e5;

I_ids = sparse(1:nP,P2PVtxIds,lambda,nP,nv);
A = vertcat(Laplace_mat,I_ids);
b = vertcat(delta,lambda*double(p2pDsts));

b = transpose(A)*b;
A = transpose(A)*A;

y = A\full(b);

