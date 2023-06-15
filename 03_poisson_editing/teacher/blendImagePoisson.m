function imret = blendImagePoisson(im1, im2, roi, targetPosition)

% input: im1 (background), im2 (foreground), roi (in im2), targetPosition (in im1)

[hdst, wdst, dim] = size(im1);
[hsrc, wsrc, ~] = size(im2);
   
pix2idxS = @(x, y) sub2ind([hsrc wsrc], y, x);
pix2idxT = @(x, y) sub2ind([hdst wdst], y, x);

[xsrc, ysrc] = meshgrid(1:wsrc, 1:hsrc);

pixflags = inpolygon(xsrc, ysrc,  roi(:,1), roi(:,2));
xsrc = [xsrc(pixflags) ysrc(pixflags)];
xdst = xsrc + mean(targetPosition-roi);

n = size(xsrc,1);
Lsrc = sparse(repmat((1:n)', 1, 5), pix2idxS(xsrc(:,1)+[0 0 0 -1 1], xsrc(:,2)+[0 -1 1 0 0]), repmat([4 -1 -1 -1 -1], size(xsrc,1), 1), n, wsrc*hsrc);
Ldst = sparse(repmat((1:n)', 1, 5), pix2idxT(xdst(:,1)+[0 0 0 -1 1], xdst(:,2)+[0 -1 1 0 0]), repmat([4 -1 -1 -1 -1], size(xdst,1), 1), n, wdst*hdst);

pixflagt = false(hdst*wdst, 1);
pixflagt(pix2idxT(xdst(:,1), xdst(:,2))) = true;

% convert to double for linear system solve
im1 = double(reshape(im1, [], dim));
im1(pixflagt, :) = Ldst(:, pixflagt) \ (Lsrc*double(reshape(im2, [], dim)) - Ldst(:, ~pixflagt)*im1(~pixflagt, :));

imret = reshape( uint8(im1), hdst, wdst, dim);

