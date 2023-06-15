classdef bezier_spline < handle
  
  properties
    ctrlPoint = [];
    dataPoint = []; %note: dataPoint = {b_0, b_1, b_2, b_3, b_3, b_4, b_5, b_6, бнбн} (easy for computing sampling points in spline)
    actPointIdx = 0;
    ButtonDownFlag = 0;
    kernelMatrix;
    FigHdl;
    AxesHdl;
  end
  methods
      function init(I)
          close all;
          %% create figure and set callback function
%           bs.ctrlPoint = rand(1000,2); %for test large ctrlPoint set
          I.FigHdl = figure;
          hold on;
          axis([-1 1 -1 1]);
          I.AxesHdl = gca;
          title('Bezier Spline');
          set(I.FigHdl, 'WindowButtonDownFcn', @(dummy1,dummy2)ButtonDownFcn(I));
          set(I.FigHdl, 'WindowButtonMotionFcn', @(dummy1,dummy2)ButtonMotionFcn(I));
          set(I.FigHdl, 'WindowButtonUpFcn', @(dummy1,dummy2)ButtonUpFcn(I));
          
          %% construct kernel matrix
          t = 0:0.001:1;
          t = t';
          % you can find out how to construct this kernel matrix in ppt of Chapter_03
          I.kernelMatrix = t.^(3:-1:0) * [-1, 3, -3, 1; 3, -6, 3, 0; -3, 3, 0, 0; 1, 0, 0, 0];
      end
      function updateDataPoint(I)
          np = size(I.ctrlPoint, 1);
          A = eye(np) * 4;
          A(1,1) = 2; A(end,end) = 2;
          A = A + diag(ones(np - 1,1), 1) + diag(ones(np - 1,1), -1);
          
          c = [I.ctrlPoint(2:end,:); I.ctrlPoint(end,:)] - [I.ctrlPoint(1,:); I.ctrlPoint(1:end-1,:)];
          
          d = A\c;
          
          I.dataPoint = zeros(4 * (np - 1), 2);
          
%           b((1 + 3*(0:np-1)),:) = I.ctrlPoint;
%           b((3*(1:np-1)),:) = I.ctrlPoint(2:end,:) - d(2:end,:);
%           b((2 + 3*(0:np-2)),:) = I.ctrlPoint(1:end - 1,:) + d(1:end - 1,:);
           I.dataPoint(4*(1:np-1) - 3,:) = I.ctrlPoint(1:end-1,:);
           I.dataPoint(4*(1:np-1) - 2,:) = I.ctrlPoint(1:end - 1,:) + d(1:end - 1,:);
           I.dataPoint(4*(1:np-1) - 1,:) = I.ctrlPoint(2:end,:) - d(2:end,:);
           I.dataPoint(4*(1:np-1),:) = I.ctrlPoint(2:end,:);
      end
      
      function updateFig(I)
          tic;
          cla(I.FigHdl);  
          if ~isempty(I.ctrlPoint)
              I.updateDataPoint;
              plot(I.ctrlPoint(:,1), I.ctrlPoint(:,2), 'b.', 'MarkerSize', 10);
              if size(I.ctrlPoint,1) > 1
                  rdataPoint = reshape(I.dataPoint, 4, []);
                  sampling_point = I.kernelMatrix * rdataPoint;
                  sampling_point = reshape(sampling_point, [], 2);
                  plot(sampling_point(:,1), sampling_point(:,2), 'b-');
              end
          end
          if I.actPointIdx ~= 0
            plot(I.ctrlPoint(I.actPointIdx,1), I.ctrlPoint(I.actPointIdx,2), 'r.', 'MarkerSize', 20);
          end
          toc;
      end
      
      function Idx = pickPoint(I, pt)
          Idx = 0;
          if isempty(I.ctrlPoint)
              return
          end
          radius = sum((I.ctrlPoint - pt).^2, 2);
          [minRadius, minRadiusId] = min(radius);
          if minRadius < 0.002
              Idx = minRadiusId;
          else
              Idx = 0;
          end
      end
      
      function resetMouse(I)
           I.ButtonDownFlag = 0;
           I.actPointIdx = 0;
      end
      
      function ButtonDownFcn(I)
          I.ButtonDownFlag = 1;
          pt = get(I.AxesHdl, 'CurrentPoint');
          p1 = pt(1,1:2);
          I.actPointIdx = I.pickPoint(p1);
          if strcmp(get(I.FigHdl, 'SelectionType'), 'normal')
              if ~I.actPointIdx
                  %add point
                  I.ctrlPoint(end + 1,:) = p1;
                  I.actPointIdx = size(I.ctrlPoint, 1);
              end
          elseif strcmp(get(I.FigHdl, 'SelectionType'), 'alt')
              if I.actPointIdx
                  %delete point
                  I.ctrlPoint(I.actPointIdx,:) = [];
                  I.actPointIdx = 0;
              end
          end
          I.updateFig;
      end
      
      function ButtonMotionFcn(I)
          pt = get(I.AxesHdl, 'CurrentPoint');
          p1 = pt(1, 1:2);
          %     p2 = pt(2, 1:2);
          if ~I.ButtonDownFlag && I.actPointIdx ~= I.pickPoint(p1)
              I.actPointIdx = I.pickPoint(p1);
              I.updateFig;
          end
          if I.actPointIdx
              if I.ButtonDownFlag
                  I.ctrlPoint(I.actPointIdx,:) = p1;
                  I.updateFig;
              end
          end
      end
      
      function ButtonUpFcn(I)
          I.resetMouse;
          I.updateFig;
      end
  end 
end