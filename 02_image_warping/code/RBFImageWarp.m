function im2 = RBFImageWarp(im, psrc, pdst,isFill)

    % input: im, psrc, pdst


    % basic image manipulations
    % get image (matrix) size
    [h, w, dim] = size(im);
    disp(psrc);
    disp(pdst);
    %im2 = im;
    im2 = zeros(h,w,dim,'uint8');
    mask_map = zeros(h,w);
    %% TODO: compute warpped image
    n = size(psrc,1);
    if(n==0)
        im2 = im;
        return;
    end
    if n==0
        return
    end
    psrc(:,[1,2])=psrc(:,[2,1]);
    pdst(:,[1,2])=pdst(:,[2,1]);
    d=sum(sum((pdst-psrc).^2));

%     if n==1
%         d = norm(pdst-psrc)^2;
%     else
%         g1 = meshgrid(psrc(:,1));
%         g2 = meshgrid(psrc(:,2));
%         sub = (g1-g1').^2+(g2-g2').^2;
%         d_inf = inf(1,n);
%         d = min(sub+diag(d_inf));
%     end
    
    coeMat = zeros(n,n);
    for i=1:n
        coeMat(i,:) = getCoeRow(psrc(i,:), psrc,d);
    end
    a = coeMat\(pdst-psrc);
 
    
    for i=1:h
        for j=1:w
            pos = [i,j];         
            b = getCoeRow(pos,psrc,d);
            trans = b*a;
            new_pos = round(trans+pos);
%            disp(new_pos);
            if new_pos(1)>0 && new_pos(1)< h+1 && new_pos(2)>0 && new_pos(2)<w+1
                im2(new_pos(1),new_pos(2),:)=im(i,j,:);
                mask_map(new_pos(1),new_pos(2))=1;
            end     
        end
    end
    if(isFill)
        im2 = fillHole(im2,mask_map);
    end
end


%获得矩阵元行向量
function r = getCoeRow(x, p,d)
    n = size(p,1);
    if n==0 
        r = 1;
        return;
    elseif(n==1)
        r = getCoeB(x,p,d);
        return;
    else
%         r = zeros(1,n);
        r = 1./(sum((x-p).^2,2)+d);
        r = reshape(r,1,n);
%         for i = 1:n
%             r(i) = getCoeB(x,p(i,:),d);
%         end
    end
end

function coe = getCoeB(x,p_i,d)
     coe = 1/(norm(x-p_i)^2+d);
end
% 插值法解决白色空洞或条纹问题
function im2 = fillHole(im,mask_map)
    [h, w, ~] = size(im);
    im2=double(im);
    for i=2:h-1
        for j=2:w-1
            if mask_map(i,j)==0
                if(any(any(mask_map(i-1:i+1,j-1:j+1))))%检查周围3*3格点中是否有已经填充像素的点
                    im2(i,j,:)=sum(sum(im2(i-1:i+1,j-1:j+1,:).*mask_map(i-1:i+1,j-1:j+1)))...
                        /sum(sum(mask_map(i-1:i+1,j-1:j+1)));
                else
                    im2(i,j,:)=[0,0,0];
                end
            end
        end
    end
    im2=uint8(im2);
end



