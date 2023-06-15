nv = size(x, 1);
nf = size(t, 1);
%范围从[-1,1]*[-1,1]映射到[0,1]*[0,1]
if(isCot)
    uv = (cot_mapping(x,t)+[1,1])./2;
else
    uv = (uniform_mapping(x,t)+[1,1])./2;
end
