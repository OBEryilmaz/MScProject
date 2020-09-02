%% Preprocessing element
% This element was added to execute the weighted summation of the colour maps.

classdef Preprocessing < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = Preprocessing(label)
      if nargin > 0
        obj.label = label;
        %obj.size = size;
      end

      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1}).*...
           obj.inputElements{3}.(obj.inputComponents{3})+ ...
           obj.inputElements{2}.(obj.inputComponents{2}).*...
           obj.inputElements{4}.(obj.inputComponents{4});
       obj.output =double(obj.output);
    end

    function obj = init(obj)
        obj.output=0;
    end
  end
end

