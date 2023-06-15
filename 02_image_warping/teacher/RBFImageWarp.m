    function [im2, q0] = RBFImageWarp(im, psrc, pdst)

%   Copyright © 2021, Renjie Chen @ USTC

% input: im, psrc, pdst

% parameter for RBF 
d = 10000;

%% map
% f(x) = x + sum_i( a_i*fRBF_i(x) );
% f(x) = x + sum_i( a_i/(d+(|x-pi|^2) );
% fRBF = @(x, y) 1./(pdist2(x, y).^2+d);
fRBF = @(x, y) exp(-(pdist2(x, y).^2/d));

%% construct matrix for linear system
A = fRBF(psrc, psrc);

%% solve for warp coefficients
coef = A\(pdst-psrc);

%% get source pixels
[h, w, ~] = size(im);
[xpix, ypix] = meshgrid(1:w, 1:h);
x = [xpix(:) ypix(:)];

%% mapped position for each source pixel
q0 = fRBF(x, psrc)*coef+x;

%% assign result image
q = ceil(q0);
pFlag = all(q>0,2) & (q(:,1)<=w) & (q(:,2)<=h);
mapPId = sub2ind([h w], q(pFlag,2), q(pFlag,1));

im = reshape(im, [h*w 3]);

im2 = ones(h*w, 3, 'uint8')*255;
im2(mapPId, :) = im(pFlag,:);
im2 = reshape(im2, [h w 3]);
