function toolMarkCB(h, varargin)

flag =  evalin('base', 'flag');
if(flag==0)
    flag=1;
    assignin('base', 'flag', flag);
end

evalin('base', 'delete(hpolys);');

set(h, 'Enable', 'off');

hp1 = drawpolygon(subplot(121));
hp1.set('InteractionsAllowed', 'translate');

hp2 = drawpolygon(subplot(122), 'position', hp1.Position);
hp2.set('InteractionsAllowed', 'translate');

assignin('base', 'hpolys', [hp1; hp2]);

set(h, 'Enable', 'on');
% toolPasteCB;
addlistener(hp2, 'MovingROI', @toolPasteCB);