figure('Units', 'pixel', 'Position', [100,100,1000,700], 'toolbar', 'none');
width = 200;
height = 200;
% 创建白色画布
canvas = ones(height, width, 3);
% 显示画布
ax1 = subplot(121);imshow(canvas);title("Bezier");
ax2 = subplot(122);imshow(canvas);title("Bezier Spline");
%% Poly Line
h_ploy = drawpolyline(ax1);
h_ploy.set('InteractionsAllowed', 'all');
h_ploy_s = drawpolyline(ax2,'Position',h_ploy.Position);
h_ploy_s.set('InteractionsAllowed', 'all');
hold(ax1, 'on');
hold(ax2, 'on');
%% Matrix Pre Compute
% 基矩阵预计算
nt = 1000;
np = size(h_ploy.Position,1);
base_mat = computeBaseMat(nt,np);
base4_mat = computeBaseMat(nt,4);
% 计算样条插值点矩阵
spline_mat = computeSplineMat(np);
%% recall func
hcurve = plot(ax1,bezier(h_ploy.Position,base_mat), 'g', 'linewidth', 2);
hcurve_s = plot(ax2,bezier_spline(h_ploy.Position,base4_mat,spline_mat), 'g', 'linewidth', 2);

h_ploy.addlistener('MovingROI', @(h, evt) bezier(evt.CurrentPosition,base_mat, hcurve));
h_ploy.addlistener('MovingROI', @(h, evt) bezier_spline(evt.CurrentPosition,base4_mat,spline_mat, hcurve_s,h_ploy_s));

h_ploy_s.addlistener('MovingROI', @(h, evt) bezier(evt.CurrentPosition,base_mat, hcurve,h_ploy));
h_ploy_s.addlistener('MovingROI', @(h, evt) bezier_spline(evt.CurrentPosition,base4_mat,spline_mat, hcurve_s));



%% bezier curve
function p = bezier(p,base,h,h_ploy)
%mat 是nt*np的矩阵,用来处理各个时间序列的坐标点
    if nargin>3
        set(h_ploy,"Position",p)
    end
    p = base*p*[1;1i];
    if nargin>2
        set(h, 'xdata', real(p), 'ydata', imag(p)); 
    end
end

function p = bezier_spline(p,base,spline_mat,h,h_ploy)
%base处理各个时间序列的坐标点的矩阵很小，而且是固定的
%spline_mat 是待计算的插值点系数矩阵
    if nargin>4
        set(h_ploy,"Position",p)
    end
    raw_p = p;
    np = size(p,1);
    b = [p;zeros(2*(np-1),2)];
    p = spline_mat\b;
    inter_p = p;
    p = p*[1;1i];    
    p_new = zeros(4,np-1);
    for k = 1:np-1
        p_new(:,k) = p((k-1)*3+1:(k)*3+1);
    end
    p = base*p_new;
    p = reshape(p,[],1);
    
    if nargin>3
        set(h, 'xdata', real(p), 'ydata', imag(p)); 
    end
end




