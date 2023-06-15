%   Copyright © 2021, Renjie Chen @ USTC


%% read image
im = imread('MonaLisa.jpg');

%% draw 2 copies of the image
f = figure('Units', 'pixel', 'Position', [100,100,1000,700], 'toolbar', 'none');
subplot(121); imshow(im); title({'Source image', 'Press the red tool button to add point-point constraints'});
subplot(122); himg = imshow(im*0); title({'Warpped Image',...
    'Press the blue tool button to compute the warpped image',...
    "Check popupmenu for warping mode"});

% uipushtool
% CDate:图标数据，后面紧跟的是icon图标
% TooltipString:鼠标悬停在图标上时显示的提示信息
% ClickedCallback:点击图标时执行的回调函数
% UserData:用户自定义数据
% checkbox = uicontrol('style', 'checkbox', 'string', 'Fill hole on/off', ...
% 'position', [0,610,200,100], 'value', 0);
% set(checkbox,"fontsize",14);

hpop = uicontrol(f,'Style','popupmenu');
hpop.Position = [0 600 180 100];
hpop.String = {'Normal','Interpolation','Reverse'};
set(hpop,"fontsize",14);
set(hpop,"Callback",@toolWarpCB);

isfill = 0;
hToolPoint = uipushtool('CData', reshape(repmat([1 0 0], 100, 1), [10 10 3]), 'TooltipString', 'add point constraints to the map', ...
                        'ClickedCallback', @toolPositionCB, 'UserData', []);
hToolWarp = uipushtool('CData', reshape(repmat([0 0 1], 100, 1), [10 10 3]), 'TooltipString', 'compute warped image', ...
                       'ClickedCallback', @toolWarpCB);

%% TODO: implement function: RBFImageWarp
% check the title above the image for how to use the simple user-interface to define point-constraints and compute the warpped image
