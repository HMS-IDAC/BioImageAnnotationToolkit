classdef sphereAnnotationTool < handle    
    properties
        Figure
        Axis
        PlaneHandle
        PlaneIndex
        PlaneLabel
        NPlanes
        Volume
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
        ClassIndex
        HLineHandle
        VLineHandle
        Center
        XSlider
        YSlider
        RSlider
        SliderZ
        XMarkers
        YMarkers
        Radius
        MaxRadius
        SphereID
        Spheres
        Circles
        CirclesHandle
        SecondChannel
        ShowingFirstChannel
        MouseIsDown
        Row0
        Col0
    end
    
    methods
        function tool = sphereAnnotationTool(V,maxRadius,nClasses,varargin)
            tool.ShowingFirstChannel = true;
            if nargin > 3
                tool.SecondChannel = varargin{1};
            end
            
            tool.Volume = V;
            tool.NPlanes = size(V,3);
            tool.PlaneIndex = 1;
            tool.ClassIndex = 1;
            
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
            
            tool.Radius = 10;
            tool.MaxRadius = maxRadius;
            tool.SphereID = 0;
            tool.Spheres = [];
            tool.Circles = cell(1,tool.NPlanes);
               
            % z
            tool.Figure = figure('Name',sprintf('Frame %d',tool.PlaneIndex),...
                'NumberTitle','off','CloseRequestFcn',@tool.closeTool,'KeyPressFcn',@tool.keyPressed,...
                'WindowButtonMotionFcn', @tool.mouseMove, 'WindowButtonDownFcn', @tool.mouseDown, 'WindowButtonUpFcn', @tool.mouseUp);%, ...
                % 'windowscrollWheelFcn', @tool.mouseScroll);
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            
            I = tool.Volume(:,:,tool.PlaneIndex);
            tool.PlaneHandle = imshow(tool.applyThresholds(I)); hold on;
            tool.Center = [size(V,2)/2 size(V,1)/2]; % x,y
            
            tool.HLineHandle = plot([1 size(V,2)],tool.Center(2)*[1 1],'r');
            tool.XMarkers{1} = plot((tool.Center(1)-tool.Radius)*[1 1],tool.Center(2)+[-5 5],'b');
            tool.XMarkers{2} = plot((tool.Center(1)+tool.Radius)*[1 1],tool.Center(2)+[-5 5],'b');
            
            tool.VLineHandle = plot(tool.Center(1)*[1 1],[1 size(V,1)],'r');
            tool.YMarkers{1} = plot(tool.Center(1)+[-5 5],(tool.Center(2)-tool.Radius)*[1 1],'b');
            tool.YMarkers{2} = plot(tool.Center(1)+[-5 5],(tool.Center(2)+tool.Radius)*[1 1],'b');
            
            dwidth = 1000;%300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal', 'Resize', 'on',...
                                'Name', 'SphereAnnotationToolPro',...
                                'CloseRequestFcn', @tool.closeTool,...
                                'Position',[100 100 dwidth 10.5*dborder+10.5*cheight],...
                                'KeyPressFcn',@tool.keyPressed);

            % class popup
            labels = cell(1,nClasses);
            for i = 1:nClasses
                labels{i} = sprintf('Class %d',i);
            end
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder+20 9.5*dborder+9.5*cheight cwidth-20 cheight],'Callback',@tool.popupManage);
            
             % x slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','x','Position',[dborder 8*dborder+8*cheight 20 cheight]);
            tool.XSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',size(V,2),'Value',tool.Center(1),'Position',[dborder+20 8*dborder+8*cheight cwidth-20 cheight],'Tag','xs');
            addlistener(tool.XSlider,'Value','PostSet',@tool.continuousSliderManage);
            
             % y slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','y','Position',[dborder 7*dborder+7*cheight 20 cheight]);
            tool.YSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',size(V,1),'Value',tool.Center(2),'Position',[dborder+20 7*dborder+7*cheight cwidth-20 cheight],'Tag','ys');
            addlistener(tool.YSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % r slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','r','Position',[dborder 6*dborder+6*cheight 20 cheight]);
            tool.RSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.MaxRadius,'Value',tool.Radius,'Position',[dborder+20 6*dborder+6*cheight cwidth-20 cheight],'Tag','rs');
            addlistener(tool.RSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % add/remove buttons
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','add','Position',[dborder+20 5*dborder+5*cheight (cwidth-20)/2-10 cheight],'Callback',@tool.buttonPushed);
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','remove','Position',[dborder+20+(cwidth-20)/2+10 5*dborder+5*cheight (cwidth-20)/2-10 cheight],'Callback',@tool.buttonPushed);
                            
            % z slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','f','Position',[dborder 3*dborder+3*cheight 20 cheight]);
            tool.PlaneLabel = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex),'Position',[dwidth-dborder-40 3*dborder+2*cheight 40 cheight],'HorizontalAlignment','Right');
            tool.SliderZ = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes,'Value',tool.PlaneIndex,'Position',[dborder+20 3*dborder+3*cheight cwidth-20 cheight],'Tag','zs');
            addlistener(tool.SliderZ,'Value','PostSet',@tool.continuousSliderManage);

            % lower threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','_t','Position',[dborder 2*dborder+cheight 20 cheight]);
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder+20 2*dborder+cheight cwidth-20 cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','^t','Position',[dborder dborder 20 cheight]);
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder+20 dborder cwidth-20 cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
%             uiwait(tool.Dialog)

            tool.MouseIsDown = false;
        end
        
        function mouseScroll(tool,src,callbackdata)
            vsc = callbackdata.VerticalScrollCount;
            if strcmp(src.Name(1:5),'Frame')
                if (vsc == -1 && tool.SliderZ.Value > tool.SliderZ.Min) || ...
                    (vsc == 1 && tool.SliderZ.Value < tool.SliderZ.Max)
                    
                    tool.SliderZ.Value = tool.SliderZ.Value+vsc;
                end
                tag = 'zs';
                val = tool.SliderZ.Value;
            end
            
            callbackdata = [];
            callbackdata.AffectedObject.Tag = tag;
            callbackdata.AffectedObject.Value = val;
            continuousSliderManage(tool,0,callbackdata);
        end
        
        function mouseDown(tool,~,~)
            p = tool.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            
            if row >= 1 && row <= size(tool.Volume,1) && col >= 1 && col <= size(tool.Volume,2)
                tool.Row0 = row;
                tool.Col0 = col;
                
                tool.RSlider.Value = 1;
                
                tool.MouseIsDown = true;
            end
        end
        
        function mouseUp(tool,~,~)
            if tool.MouseIsDown
                src.String = 'add';
                buttonPushed(tool,src,[]);
                
                tool.RSlider.Value = 10;
                tool.MouseIsDown = false;
            end
        end
        
        function mouseMove(tool,~,~)
            p = tool.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if tool.MouseIsDown
                if row >= 1 && row <= size(tool.Volume,1) && col >= 1 && col <= size(tool.Volume,2)
                    d = sqrt((row-tool.Row0)^2+(col-tool.Col0)^2);
                    if d >= 1 && d <= tool.MaxRadius
                        tool.RSlider.Value = d;
                    end
                end
            else
                if row >= 1 && row <= size(tool.Volume,1) && col >= 1 && col <= size(tool.Volume,2)
                    tool.XSlider.Value = col;
                    tool.YSlider.Value = row;
                end
            end
        end
        
        function keyPressed(tool,~,event)
            if strcmp(event.Key,'space')
                if ~isempty(tool.SecondChannel)
                    if tool.ShowingFirstChannel
                        I = tool.SecondChannel(:,:,tool.PlaneIndex);
                        tool.PlaneHandle.CData = tool.applyThresholds(I);
                        
                        tool.ShowingFirstChannel = false;
                    else
                        I = tool.Volume(:,:,tool.PlaneIndex);
                        tool.PlaneHandle.CData = tool.applyThresholds(I);
                        
                        tool.ShowingFirstChannel = true;
                    end
                end
            end
            
            addToZ = 0;
            if strcmp(event.Key,'add') || strcmp(event.Key,'equal') || strcmp(event.Key,'rightarrow') || strcmp(event.Key,'uparrow')
                addToZ = 1;
            elseif strcmp(event.Key,'subtract') || strcmp(event.Key,'hyphen') || strcmp(event.Key,'leftarrow') || strcmp(event.Key,'downarrow')
                addToZ = -1;
            end
            
            if addToZ ~= 0
                candidatePlaneIndex = tool.PlaneIndex+addToZ;
                % fprintf('...\ncurrent z: %d, candidate z: %d\n', tool.PlaneIndex, candidatePlaneIndex);
                if candidatePlaneIndex >= 1 && candidatePlaneIndex <= tool.NPlanes
                    tool.PlaneIndex = candidatePlaneIndex;

                    I = tool.Volume(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                    
                    tool.SliderZ.Value = tool.PlaneIndex;
                end
                % fprintf('current z: %d\n', tool.PlaneIndex);
            end
        end
        
        function buttonPushed(tool,src,~)
            if strcmp(src.String,'add')
                cz = tool.PlaneIndex;
                r = tool.Radius;
                nz = tool.NPlanes;
                
                tool.SphereID = tool.SphereID+1;
                tool.Spheres = [tool.Spheres; [tool.SphereID tool.ClassIndex tool.Center cz r]];
                
                for iPlane = max(cz-r+1,1):min(cz+r-1,nz)
                    radForPlane = sqrt(r^2-(iPlane-cz)^2);
                    circlesForPlane = [tool.Circles{iPlane}; [tool.SphereID tool.ClassIndex tool.Center radForPlane]];
                    tool.Circles{iPlane} = circlesForPlane;
                end
                redrawCircles(tool);
                
                disp('added sphere')
                disp(tool.Spheres)
            elseif strcmp(src.String,'remove')
                validSpheres = tool.Spheres(tool.Spheres(:,2) == tool.ClassIndex,:);
                if ~isempty(validSpheres)
                    cx = tool.Center(1); cy = tool.Center(2); cz = tool.PlaneIndex;
                    centers = validSpheres(:,3:5);
                    distances = sqrt(sum((repmat([cx cy cz],[size(centers,1) 1])-centers).^2,2));
                    [dm,im] = min(distances);
                    r = validSpheres(im(1),6);
                    if dm(1) < r
                        id = validSpheres(im(1),1);
                        cz = validSpheres(im(1),5);
                        tool.Spheres(tool.Spheres(:,1) == id,:) = [];
                        for iPlane = max(cz-r+1,1):min(cz+r-1,tool.NPlanes)
                            circlesForPlane = tool.Circles{iPlane};
                            circlesForPlane(circlesForPlane(:,1) == id,:) = [];
                            tool.Circles{iPlane} = circlesForPlane;
                        end
                    end
                    redrawCircles(tool);
                    
                    disp('removed sphere')
                    disp(tool.Spheres)
                end
            end
        end
        
        function redrawCircles(tool)
            circles = tool.Circles{tool.PlaneIndex};
            axes(tool.Axis);
            delete(tool.CirclesHandle);
            if ~isempty(circles)
                circles = circles(circles(:,2) == tool.ClassIndex,:);
                tool.CirclesHandle = viscircles(circles(:,3:4),circles(:,5),'Color','blue','LineWidth',1);
            end
        end
        
        function popupManage(tool,src,~)
            tool.ClassIndex = src.Value;
            redrawCircles(tool);
        end
        
        function continuousSliderManage(tool,~,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts') || strcmp(tag,'lts')
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                end
                
                if isempty(tool.SecondChannel) || tool.ShowingFirstChannel
                    I = tool.Volume(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                else
                    I = tool.SecondChannel(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                end
                
            elseif strcmp(tag,'zs')
                tool.PlaneIndex = round(value);
                tool.PlaneLabel.String = sprintf('%d',tool.PlaneIndex);
                tool.Figure.Name = sprintf('Frame %d',tool.PlaneIndex);

                if isempty(tool.SecondChannel) || tool.ShowingFirstChannel
                    I = tool.Volume(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                else
                    I = tool.SecondChannel(:,:,tool.PlaneIndex);
                    tool.PlaneHandle.CData = tool.applyThresholds(I);
                end
                
                redrawCircles(tool);
            elseif strcmp(tag,'xs')
                tool.Center(1) = round(value);
                tool.VLineHandle.XData = tool.Center(1)*[1 1];
                tool.YMarkers{1}.XData = tool.Center(1)+[-5 5];
                tool.YMarkers{2}.XData = tool.Center(1)+[-5 5];
                tool.XMarkers{1}.XData = (tool.Center(1)-tool.Radius)*[1 1];
                tool.XMarkers{2}.XData = (tool.Center(1)+tool.Radius)*[1 1];
            elseif strcmp(tag,'ys')
                tool.Center(2) = round(value);
                tool.HLineHandle.YData = tool.Center(2)*[1 1];
                tool.XMarkers{1}.YData = tool.Center(2)+[-5 5];
                tool.XMarkers{2}.YData = tool.Center(2)+[-5 5];
                tool.YMarkers{1}.YData = (tool.Center(2)-tool.Radius)*[1 1];
                tool.YMarkers{2}.YData = (tool.Center(2)+tool.Radius)*[1 1];
            elseif strcmp(tag,'rs')
                tool.Radius = round(value);
                tool.XMarkers{1}.XData = (tool.Center(1)-tool.Radius)*[1 1];
                tool.XMarkers{1}.YData = tool.Center(2)+[-5 5];
                tool.XMarkers{2}.XData = (tool.Center(1)+tool.Radius)*[1 1];
                tool.XMarkers{2}.YData = tool.Center(2)+[-5 5];
                tool.YMarkers{1}.XData = tool.Center(1)+[-5 5];
                tool.YMarkers{1}.YData = (tool.Center(2)-tool.Radius)*[1 1];
                tool.YMarkers{2}.XData = tool.Center(1)+[-5 5];
                tool.YMarkers{2}.YData = (tool.Center(2)+tool.Radius)*[1 1];
            end
        end
        
        function T = applyThresholds(tool,I)
            T = I;
            T(T < tool.LowerThreshold) = tool.LowerThreshold;
            T(T > tool.UpperThreshold) = tool.UpperThreshold;
            T = T-min(T(:));
            T = T/max(T(:));
        end
        
        function closeTool(tool,~,~)
            delete(tool.Figure)
            delete(tool.Dialog);
        end
    end
end
