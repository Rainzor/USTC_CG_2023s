function toolWarpCB(varargin)

%   Copyright © 2021, Renjie Chen @ USTC

%使用主程序中的函数
hlines = evalin('base', 'hToolPoint.UserData');
im = evalin('base', 'im');
himg = evalin('base', 'himg');
% isFill = evalin('base', 'checkbox.Value');
popValue = evalin('base', 'hpop.Value');

p2p = zeros(numel(hlines)*2,2); 
for i=1:numel(hlines)
    p2p(i*2+(-1:0),:) = hlines(i).getPosition();
end

switch popValue
    case 1
        im2 = RBFImageWarp(im, p2p(1:2:end,:), p2p(2:2:end,:),0);
    case 2
        im2 = RBFImageWarp(im, p2p(1:2:end,:), p2p(2:2:end,:),1);
    case 3
        im2 = RBFImageWarpReverse(im, p2p(1:2:end,:), p2p(2:2:end,:));
end
set(himg, 'CData', im2);

