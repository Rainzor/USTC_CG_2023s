function toolPositionCB(h, varargin)

%   Copyright © 2021, Renjie Chen @ USTC


set(h, 'Enable', 'off');
toolWarpCB;
subplot(131);
hImLines = [h.UserData, imline];
set(h, 'Enable', 'on', 'UserData', hImLines);


hImLines(end).addNewPositionCallback(@toolWarpCB);

