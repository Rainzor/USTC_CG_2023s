function [imret,X0] = blendImagePoisson(im1,im2,targetPosition,roi,varargin)

    % input: im1 (background), im2 (foreground), roi (in im2), targetPosition (in im1)
    % varargin:
    % mask: Domain of definition
    % spm: sparse matrix
    % L: the sparse matrix decomposition
    % X0: last solved result. A more reasonable initial estimate value than the default zero vector.
    %% TODO: compute blended image
    source_points = round(roi);
    target_points = round(targetPosition);
    if(isempty(varargin))
       [mask,spm,L] = preprocess(im1,targetPosition,roi);      
        num_inside = sum(sum(mask));
        X0 = zeros(num_inside,3);   
    elseif(length(varargin)<4)
        mask = varargin{1};
        spm = varargin{2};
        L = varargin{3};
        num_inside = sum(sum(mask));
        X0 = zeros(num_inside,3);   
    else   
        mask = varargin{1};
        spm = varargin{2};
        L = varargin{3};
        X0 = varargin{4};
        num_inside = sum(sum(mask));
    end
    
    num_point = size(roi, 1);
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

    source_start = [x_min, y_min];
    target_start = source_start + delta;

    if (target_start(1) < 1)
        target_start(1) = 1;
    end

    if (target_start(2) < 1)
        target_start(2) = 1;
    end
    B = getDiv(im1, im2, target_start, source_start, mask);
    num_inside = sum(sum(mask));
    X = zeros(num_inside,3);
    tol = 1e-11; % 收敛容许误差
    maxit = 1000; % 最大迭代次数
    [X(:,1), ~, ~, ~] = pcg(spm, B(:,1), tol, maxit, L, L',X0(:,1));
    [X(:,2), ~, ~, ~] = pcg(spm, B(:,2), tol, maxit, L, L',X0(:,2));
    [X(:,3), ~, ~, ~] = pcg(spm, B(:,3), tol, maxit, L, L',X0(:,3));
    X0 = X;
    imret = blendImage(im1, im2, target_start, source_start, mask, X);
    
    %% TEST 
%     imret = im1;
%     [height,width]=size(mask);
%     [height_s, width_s, ~] = size(im2);
%     [height_t, width_t, ~] = size(im1);
%     for i = 1:height
%         for j = 1:width
%             if mask(i, j) == 0
%                 continue;
%             end
%             if (i + source_start (2) - 1) > height_s || (j + source_start(1) - 1) > width_s
%                 continue;
%             end
%             if (i + target_start(2) - 1) > height_t || (j + target_start(1) - 1) > width_t
%                 continue;
%             end
%             imret(i + target_start(2) - 1, j + target_start(1) - 1, :) = im2(i + source_start (2) - 1, j + source_start(1) - 1, :);
%         end
% 
%     end

end

function div_vec = getDiv(target_im, source_im, target_start, source_start, mask)
    % 获取待解向量B
    % input: target_im (background), source_im (foreground)
    % source_start (top-left corner of the source image in im2)
    % target_start (top-left corner of the target image in im1)
    % width, height (size of the source image)
    [height,width] = size(mask);
    inside_sum = sum(sum(mask));
    target_im = double(target_im);
    source_im = double(source_im);
    div_vec = zeros(inside_sum, 3,'double');
    [height_s, width_s, ~] = size(source_im);
    [height_t, width_t, ~] = size(target_im);
    l = 1;
    for j = 1:width
        for i = 1:height
            if (mask(i, j) == 1)
                s_i = i + source_start(2) - 1;
                s_j = j + source_start(1) - 1;
                t_i = i + target_start(2) - 1;
                t_j = j + target_start(1) - 1;
                if (s_i) > height_s || (s_j) > width_s || (t_i) > height_t || (t_j) > width_t
                    continue;
                end
                
                if (((i > 1) && mask(i - 1, j) == 0) && (s_i - 1) >= 1 && (t_i - 1) >= 1)
                        div_vec(l, :) = div_vec(l, :) + reshape(target_im(t_i - 1, t_j, :) - source_im(s_i - 1, s_j, :), [1, 3]);
                end

                if (((i < height) && mask(i + 1, j) == 0) && (s_i + 1) <= height_s && (t_i + 1) <= height_t)
                    
                    div_vec(l, :) = div_vec(l, :) + reshape(target_im(t_i + 1, t_j, :) - source_im(s_i + 1, s_j, :), [1, 3]);
                end

                if (((j > 1) && mask(i, j - 1) == 0) && (s_j - 1) >= 1 && (t_j - 1) >= 1)
                    div_vec(l, :) = div_vec(l, :) + reshape(target_im(t_i, t_j - 1, :) - source_im(s_i, s_j - 1, :), [1, 3]);
                end

                if  (((j < width) && mask(i, j + 1) == 0) && (s_j + 1) <= width_s && (t_j + 1) <= width_t)
                    div_vec(l, :) = div_vec(l, :) + reshape(target_im(t_i, t_j + 1, :) - source_im(s_i, s_j + 1, :), [1, 3]);
                end
                l = l+1;
            end
        end
    end
end


function imret = blendImage(target_im, source_im,target_start,source_start, mask,X)
    % 图形融合
    % input: im1 (background), im2 (foreground)
    % source_points (points in im2), target_points (points in im1)
    % source_start (top-left corner of the source image in im2)
    % target_start (top-left corner of the target image in im1)
    % width, height (size of the source image)
    [height,width] = size(mask);
    imret = target_im;
    source_im = double(source_im);
    [height_s, width_s, ~] = size(source_im);
    [height_t, width_t, ~] = size(target_im);
    l = 1;
    for j = 1:width
        for i = 1:height
            if (mask(i, j) == 1)
                s_i = i + source_start(2) - 1;
                s_j = j + source_start(1) - 1;
                t_i = i + target_start(2) - 1;
                t_j = j + target_start(1) - 1;                
                if (s_i) > height_s || (s_j) > width_s || (t_i) > height_t || (t_j) > width_t
                    continue;
                end
                imret(t_i, t_j, :) = uint8(reshape(X(l, :),[1,1,3]) + source_im(s_i, s_j, :));
                l = l+1;
            end
        end
    end

end