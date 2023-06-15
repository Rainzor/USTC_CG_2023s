function toolPasteCB(varargin)

hpolys = evalin('base', 'hpolys');

roi = hpolys(1).Position();
targetPosition = roi + ceil(hpolys(2).Position - roi);

im1 = evalin('base', 'im1');
im2 = evalin('base', 'im2');
himg = evalin('base', 'himg');

flag =  evalin('base', 'flag');
if(flag==1)
    %预处理函数
    [mask,spm,L] = preprocess(im1,targetPosition,roi);
    flag=0;
    % 可以使用 persisent 声明静态变量，而不是调用base的全局变量
    assignin('base', 'mask', mask);
    assignin('base', 'L', L);
    assignin('base', 'spm', spm);
    assignin('base', 'flag', flag);
    [imdst,X0] = blendImagePoisson(im1,im2,targetPosition,roi,mask,spm,L);
    assignin('base', 'X0', X0);
else
    L = evalin('base', 'L');
    spm = evalin('base', 'spm');
    mask = evalin('base', 'mask');
    X0 = evalin('base', 'X0');
    [imdst,X0] = blendImagePoisson(im1,im2,targetPosition,roi,mask,spm,L,X0);
    assignin('base', 'X0', X0);
end
set(himg, 'CData', imdst);
