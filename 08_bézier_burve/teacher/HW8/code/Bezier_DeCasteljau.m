figure; 
xlim([0,10]);
ylim([0,10]);
t = 0:0.001:1;

%%
h = drawpolyline('Color','blue','LineWidth',1);
hold on;
p = bezier(h.Position, t);
hcurve = plot(p, 'r', 'linewidth', 1);
h.addlistener('MovingROI', @(h, evt) bezier(evt.CurrentPosition, t, hcurve));

%%
function p = bezier(p, t, h)
    p = p*[1;1i];     % convert to complex numbers
    while size(p,1)>1
        p = p(1:end-1,:).*(1-t) + p(2:end,:).*t;
    end
    if nargin>2
        set(h, 'xdata', real(p), 'ydata', imag(p));
    end
end