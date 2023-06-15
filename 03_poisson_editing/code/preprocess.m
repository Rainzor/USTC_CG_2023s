function [mask,spm, L] = preprocess(target_im,targetPosition,roi)
    %预处理函数，用来提前处理稀疏矩阵分解与掩码图的制作
    %所谓掩码图，就是用来确定边界的
    % input: points (in im2), start_point (top-left corner of the source image in im2)
    % width, height (size of the source image)
    % if the point inside the polygen, then mask = 1
    % if the point outside the polygen, then mask = 0
    
    source_points = round(roi);
    target_points = round(targetPosition);
    [h_t,w_t,~] = size(target_im);
    num_point = size(roi, 1);
    
    %制作一个矩形区域，缩小搜索范围
    x_max = 0;
    x_min = inf;
    y_max = 0;
    y_min = inf;
    source_start = source_points(1, :);
    target_start = target_points(1, :);
    delta = target_start - source_start;

    for i = 1:num_point

        if x_max < source_points(i, 1)
            x_max = source_points(i, 1);
        end

        if x_min > source_points(i, 1)
            x_min = source_points(i, 1);
        end

        if y_max < source_points(i, 2)
            y_max = source_points(i, 2);
        end

        if y_min > source_points(i, 2)
            y_min = source_points(i, 2);
        end

    end

    width = x_max - x_min + 1;
    height = y_max - y_min + 1;

    source_start = [x_min, y_min];
    target_start = source_start + delta;

    if (target_start(1) < 1)
        target_start(1) = 1;
    end

    if (target_start(2) < 1)
        target_start(2) = 1;
    end

    if (target_start(1) + width - 1 > w_t)
        width = w1 - target_start(1);
    end

    if (target_start(2) + height - 1 > h_t)
        height = h1 - target_start(2);
    end
    %确定定义域和边界
    mask = zeros(height, width);
    n = height * width;
    xv = source_points(:, 2);
    yv = source_points(:, 1);
    xq = reshape(meshgrid(1:height, 1:width)', 1, n) + source_start(2) - 1;
    yq = reshape(meshgrid(1:width, 1:height), 1, n) + source_start(1) - 1;
    [in, ~] = inpolygon(xq, yq, xv, yv);
    mask(in) = 1;
    num_inside = sum(in); 
    inside_index = find(in);%所有内部点的索引

    
   %稀疏矩阵构建 
    sparse_coeff = zeros(n * 5, 3);
    k = 1;
    l = 1;
    for j = 1:width
        for i = 1:height
            if (mask(i, j) == 1)
%                 index = sub2ind([height, width], i, j);
%                 if(isempty(find(inside_index==index, 1)))
%                     disp("Element not found.");
%                 end
                sparse_coeff(k, :) = [l, l, 4];
                k = k + 1;
                
                if (i > 1 && mask(i - 1, j) == 1)
                        index2 = sub2ind([height, width], i - 1, j);
                        l2 = find(inside_index==index2);
                        sparse_coeff(k, :) = [l, l2, -1];
                        k = k + 1;
                end

                if (i < height && mask(i + 1, j) == 1)
                    index2 = sub2ind([height, width], i + 1, j);
                    l2 = find(inside_index==index2);
                    sparse_coeff(k, :) = [l, l2, -1];
                    k = k + 1;
                end

                if (j > 1 && mask(i, j - 1) == 1)
                    index2 = sub2ind([height, width], i, j - 1);
                    l2 = find(inside_index==index2);
                    sparse_coeff(k, :) = [l, l2, -1];
                    k = k + 1;
                end

                if (j < width && mask(i, j + 1) == 1)
                    index2 = sub2ind([height, width], i, j + 1);
                    l2 = find(inside_index==index2);
                    sparse_coeff(k, :) = [l, l2, -1];
                    k = k + 1;
                end
                l = l + 1;

            end

        end

    end

%    spm = sparse(sparse_coeff(1:k - 1, 1), sparse_coeff(1:k - 1, 2), sparse_coeff(1:k - 1, 3), n, n);
    spm = sparse(sparse_coeff(1:k - 1), sparse_coeff(1:k - 1, 2), sparse_coeff(1:k - 1, 3), num_inside, num_inside);
    L = ichol(spm, struct('type', 'ict', 'droptol', 1e-7));
    %[L,U] = lu(spm);
end
