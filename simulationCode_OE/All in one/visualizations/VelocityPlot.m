% VelocityPlot created by modifying RGBImage (COSIVINA toolbox) 

%   Plots a 3xMxN matrix as an RGB image using the Matlab image function.
%
% Constructor call: VelocityPlot(plotElement, plotComponent, ...
%   axesProperties, , title, xlabel, ylabel, position)
%
% Arguments:
% imageElement - label of the element whose component should be
%   visualized
% imageComponent - name of the element component that should be plotted
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for
%   further information)
%  - cell array containing a list of valid image object
%   settings (as property/value pairs) that can be applied to the image
%   handle via the set function (optional, see Matlab documentation on
%   the image function for further information)
% title - string specifying an axes title (optional)
% xlabel - string specifying an x-axis label (optional)
% ylabel - string specifying a y-axis label (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = VelocityPlot('camera grabber', 'output', {'YDir', 'normal'}, {}, ...
%   'camera image');


classdef VelocityPlot < Visualization
    properties
        
        
        plotElementHandleX
        plotElementHandleY
        plotElementLabel
        plotComponentX
        plotComponentY
        
        plotHandle
        plotProperties
        
        axesHandle
        axesProperties
        
        title = '';
        xlabel = '';
        ylabel = '';
        
        titleHandle = 0;
        xlabelHandle = 0;
        ylabelHandle = 0;
    end
    
    methods
        % Constructor
        function obj = VelocityPlot(plotElement, plotComponentX,plotComponentY, ...
                axesProperties,plotProperties,title, xlabel, ylabel, position)
            
            
            obj.plotElementLabel = plotElement;
            obj.plotComponentX = plotComponentX;
            obj.plotComponentY = plotComponentY;
            obj.axesProperties = {};
            obj.plotProperties = {};
            obj.position = [];
            obj.axesHandle = 0;
            
            obj.plotHandle =0;
            
            
            if nargin >= 4
                obj.axesProperties = axesProperties;%plotProperties
            end
           
            if nargin >= 5
                obj.plotProperties = plotProperties;%plotProperties
            end
           
            if nargin >= 6 && ~isempty(title)
                obj.title = title;
            end
            if nargin >= 7 && ~isempty(xlabel)
                obj.xlabel = xlabel;
            end
            if nargin >= 8 && ~isempty(ylabel)
                obj.ylabel = ylabel;
            end
            if nargin >= 9
                obj.position = position;
            end
        end
        
        
        % connect to simulator object
        function obj = connect(obj, simulatorHandle)
            if simulatorHandle.isElement(obj.plotElementLabel)
                obj.plotElementHandleX = simulatorHandle.getElement(obj.plotElementLabel);
                if ~obj.plotElementHandleX.isComponent(obj.plotComponentX) ...
                        && ~obj.plotElementHandleX.isParameter(obj.plotComponentX)
                    error('ExtendedRGBImage:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
                        obj.plotComponentX, obj.plotElementLabel);
                end
            else
                error('ExtendedRGBImage:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabel);
            end
            
            
            if simulatorHandle.isElement(obj.plotElementLabel)
                obj.plotElementHandleY = simulatorHandle.getElement(obj.plotElementLabel);
                if ~obj.plotElementHandleY.isComponent(obj.plotComponentY) ...
                        && ~obj.plotElementHandleY.isParameter(obj.plotComponentY)
                    error('ExtendedRGBImage:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
                        obj.plotComponentY, obj.plotElementLabel);
                end
            else
                error('ExtendedRGBImage:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabel);
            end
        end
           
        
        % initialization
        function obj = init(obj, figureHandle)
            obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position);
         
            
           obj.plotHandle=plot(obj.plotElementHandleX.(obj.plotComponentX),obj.plotElementHandleY.(obj.plotComponentY),'Parent',obj.axesHandle,...
                obj.plotProperties{:});
            
            if ~isempty(obj.axesProperties)
                set(obj.axesHandle, obj.axesProperties{:});
            end
            
            if ~isempty(obj.title)
                obj.titleHandle = title(obj.axesHandle, obj.title); %#ok<CPROP>
            end
            if ~isempty(obj.xlabel)
                obj.xlabelHandle = xlabel(obj.axesHandle, obj.xlabel); %#ok<CPROP>
            end
            if ~isempty(obj.ylabel)
                obj.ylabelHandle = ylabel(obj.axesHandle, obj.ylabel); %#ok<CPROP>
            end
        end
        
        
        % update
        function obj = update(obj)
            xdata = get(obj.plotHandle, 'XData');  
            ydata = get(obj.plotHandle, 'YData');
            set(obj.plotHandle, 'XData', [xdata, obj.plotElementHandleX.(obj.plotComponentX)+1], 'YData', [ydata, obj.plotElementHandleY.(obj.plotComponentY)]);
        end
        
    end
    
end