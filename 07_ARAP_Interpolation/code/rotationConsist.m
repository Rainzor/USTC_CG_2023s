function output = rotationConsist(e2t,t,theta)
%旋转一致性算法
%广度优先遍历面元
%处理相邻面元连续性
    queue = 1;
    nt = size(t,1);
    waitlist = ones(nt,1);
    waitlist(1) = 0;
    while queue
        head = queue(1);
        t_head = t(head,:);
        t_adj = zeros(1,3);
        %寻找相邻三角形，
        %如果边1->2所在三角形为A,
        %那么2->1所在三角形B，与A相邻
        t_adj(1) = e2t(t_head(2),t_head(1));
        t_adj(2) = e2t(t_head(3),t_head(2));
        t_adj(3) = e2t(t_head(1),t_head(3));
        t_adj = t_adj(t_adj ~=0);
        t_adj(waitlist(t_adj)==0) = [];%已经处理过的三角形不再重复处理
        for l = t_adj'
            while theta(head) - theta(l) > pi
                theta(l) = theta(l)+2*pi;
            end
            while theta(head) - theta(l) < -pi
                theta(l) = theta(l)-2*pi;
            end
        end
        waitlist(t_adj) = 0;
        queue = [queue,t_adj];
        queue(1) = [];
    end
    output = theta;
end