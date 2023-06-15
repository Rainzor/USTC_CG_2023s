% x=linspace(0,2*pi,100);
% y=sin(x);

figure;
% h = drawpolyline('Position',[x' y']);
h = drawpolyline;
hold on;
t=0:0.001:1;
hcurve = plot(BezierCurve(h.Position, t), 'g', 'linewidth', 2, 'Color', 'r');
xlim([0, 1]);
ylim([0, 1]);
axis on;
h.addlistener('MovingROI', @(h, evt) BezierCurve(evt.CurrentPosition, t, hcurve));

% bezier(h.Position,t,hcurve);

%% 
function x = BezierCurve(p, t, h)
    % Description: compute bezier curve by calculating the coordinates of the curve at t
    % Input: p -- coordinates of control points
    %        t -- time
    %        h -- figure
    % Output: x -- % the coordinates of the curve at t

    n = size(p, 1); % the number of control points
    x = zeros(length(t), 2); % the coordinates of the curve at t

    % p=p*[1;1i];
    % for j=1:n-1
    %     p(1:n-j)=(1-t).*p(1:n-j)+t.*p(2:n-j+1); % try to vectorization
    % end
    for i = 1:length(t)
        time = t(i);
        b = p;

        for j = 1:n - 1
            b(1:n - j, :) = (1 - time) * b(1:n - j, :) + time * b(2:n - j + 1, :);
        end

        x(i, :) = b(1, :);
    end

    if nargin > 2
        set(h, 'xdata', x(:, 1), 'ydata', x(:, 2));
        % print(gcf, 'BezierCurveManyPoints', '-depsc');
        % set(h,'xdata',real(p),'ydata',imag(p));
    end

end