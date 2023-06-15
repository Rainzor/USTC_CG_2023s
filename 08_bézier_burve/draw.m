function draw(p)
    % 生成示例数据
    x = real(p);
    y = imag(p);
    % 创建颜色向量
    colors = linspace(0, 1, length(x));
    cmap = colormap; % 使用当前的颜色映射（默认为'parula'）
    color_indices = ceil(colors * (size(cmap, 1) - 1)) + 1;
    colors = cmap(color_indices, :);
    % 绘制曲线
    scatter(x, y,20, colors)
end
