function im2 = RBFImageWarpReverse(im, psrc, pdst)

    % input: im, psrc, pdst


    % basic image manipulations
    % get image (matrix) size
    [h, w, dim] = size(im);
    disp(psrc);
    disp(pdst);
    %im2 = im;
    im2 = zeros(h,w,dim,'uint8');
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
    if n==1
        d = norm(pdst-psrc)^2;
    else
        g1 = meshgrid(pdst(:,1));
        g2 = meshgrid(pdst(:,2));
        sub = (g1-g1').^2+(g2-g2').^2;
        d_inf = inf(1,n);
        d = min(sub+diag(d_inf));
    end
    coeMat = zeros(n,n);
    for i=1:n
        coeMat(i,:) = getCoeRow(pdst(i,:), pdst,d);% Replace psrc to pdst
    end
    a = coeMat\(psrc-pdst);
 
    for i=1:h
        for j=1:w
            pos = [i,j];         
            b = getCoeRow(pos,pdst,d);
            trans = b*a;
            new_pos = round(trans+pos);
%            disp(new_pos);
            if new_pos(1)>0 && new_pos(1)< h+1 && new_pos(2)>0 && new_pos(2)<w+1
                im2(i,j,:)=im(new_pos(1),new_pos(2),:);
            end     
        end
    end
end



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
        dis_tmp =reshape(sum((x-p).^2,2),1,n);
        r = 1./(dis_tmp+d);
%         for i = 1:n
%             r(i) = getCoeB(x,p(i,:),d(i));
%         end
    end
end

function coe = getCoeB(x,p_i,d)
     coe = 1/(norm(x-p_i)^2+d);
end


