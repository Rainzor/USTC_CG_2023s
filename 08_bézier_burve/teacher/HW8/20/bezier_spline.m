figure;
h = drawpolyline;
hold on;
t = 0:0.001:1;
hcurve = plot(bezier_spline_uniform(h.Position, t), 'g', 'linewidth', 2, 'Color', 'r');
xlim([0, 1]);
ylim([0, 1]);
axis on;
h.addlistener('MovingROI', @(h, evt) bezier_spline_uniform(evt.CurrentPosition, t, hcurve));

%% Functions
function x = BezierCurve(p, t, h)
    % Description: compute bezier curve by calculating the coordinates of the curve at t
    % Input: p -- coordinates of control points
    %        t -- time
    %        h -- figure
    % Output: x -- % the coordinates of the curve at t

    n = size(p, 1); % the number of control points
    x = zeros(length(t), 2); % the coordinates of the curve at t

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
    end

end

function b = bezier_spline_uniform(k, t, h)
    % Description: compute control points of bezier spline of uniform parameterization
    % Input: k -- coordinates of interpolation points
    % Output: b -- coordinates of control points

    %% Construct Linear System and Solve it
    n = length(k); % the number of interpolation points
    A = sparse(repmat((2:n - 2)', 1, 3), (2:n - 2)' + [-1 0 1], repmat([1 4 1], n - 3, 1), n - 1, n - 1);
    A(1, [1 2]) = [2 1];
    A(n - 1, [n - 2 n - 1]) = [2 7];

    rhs_vec = zeros(n - 1, 2);
    rhs_vec(2:n - 2, :) = 4 * k(2:n - 2, :) + 2 * k(3:n - 1, :);
    rhs_vec(1, :) = k(1, :) + 2 * k(2, :);
    rhs_vec(n - 1, :) = k(n, :) + 8 * k(n - 1, :);

    x = A \ rhs_vec;
    y = zeros(n - 1, 2);
    y(1:n - 2, :) = 2 * k(2:n - 1, :) - x(2:n - 1, :);
    y(n - 1, :) = 4 * x(n - 1, :) + x(n - 2, :) - 4 * k(n - 1, :);

    b = zeros(3 * n - 2, 2); % concatenate all points
    b(1:3:3 * n - 2, :) = k;
    b(2:3:3 * n - 4, :) = x;
    b(3:3:3 * n - 3, :) = y;

    len = length(t);
    coord = zeros((n - 1) * len, 2); % the coordinates of the curve at t

    for curve_num = 1:n - 1
        coord((curve_num - 1) * len + 1:curve_num * len, :) = BezierCurve(b((curve_num-1)*3+1:curve_num*3+1, :), t);
    end

    if nargin > 2
        set(h, 'xdata', coord(:, 1), 'ydata', coord(:, 2));
        % print(gcf, 'BezierSplineManyPoints', '-depsc');
    end

end

% function b = bezier_spline_chordal(k)
%     % Description: compute control points of bezier spline of chordal parameterization
%     % Input: k -- coordinates of interpolation points
%     % Output: b -- coordinates of control points
%
%     n = length(k);
%     % t = 1:n; % uniform parameter
%
%
%     end
%     % A = sparse(1:n, 3 * (0:n - 1) + 1, 1); % for interpolation condition
%     % sparse(1:n - 2, 3 * (1:n - 2)' + 1 + [-1 0 1], )
% end
