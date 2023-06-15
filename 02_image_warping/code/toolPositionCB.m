function toolPositionCB(h, varargin)%   Copyright © 2021, Renjie Chen @ USTC

set(h, 'Enable', 'off');

subplot(121);
hImLines = [h.UserData, imline];
set(h, 'Enable', 'on', 'UserData', hImLines);

toolWarpCB;
hImLines(end).addNewPositionCallback(@toolWarpCB);
