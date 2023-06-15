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
    p = p*[1;1i];               % convert to complex numbers
    r = size(p,1) - 1;          % r + 1 = number of control points
    i = 0:r;
    M = factorial(r) ./ repmat(factorial(i) .* factorial(r - i),length(t'),1)...
        .* t'.^i .* (1 - t').^(r - i);
    p = M * p;
    if nargin>2
        set(h, 'xdata', real(p), 'ydata', imag(p));
    end
end