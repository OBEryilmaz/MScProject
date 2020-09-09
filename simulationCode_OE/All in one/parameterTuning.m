% parameter tuning for the choice reaching task model OE
clear all;
close all;
clc;
%Pick the image for target selection
pwd = 'C:\Users\omer\Desktop\cosivina';

imageNames={'redTargetOnTheLeft.png',...
    'redTargetInTheMiddle.png','redTargetOnTheRight.png','greenTargetOnTheLeft.png',...
    'greenTargetInTheMiddle.png','greenTargetOnTheRight.png','NoTargetImage.png'};

fieldSize=[120, 120];
currentSelection = 1;
connectionValue = -2; %Amplitude for connections can be different for each one
historyDuration = 100;
samplingRange = [-10, 10];
samplingResolution = 0.05;
tStimOn=0;

sigmaInhY = 10;
sigmaInhX = 10;
amplitudeInh_dv = 0.8;
sigmaExcY = 5;
sigmaExcX = 5;
amplitudeExc = 5;

amplitudeGlobal_dd=-0.01;
amplitudeGlobal_dv=-0.005;
i=1;
sim = Simulator();

sim.addElement(ModifiedImageLoader('targetImage',pwd,imageNames,fieldSize,currentSelection));

sim.addElement(SingleNodeDynamics('nodeRed', 10, -1.5, 4, 1, 0.2, samplingRange, samplingResolution), 'targetImage','inputForRed');
sim.addElement(SingleNodeDynamics('nodeGreen', 10, -1.5, 4, 1, 0.2, samplingRange, samplingResolution), 'targetImage','inputForGreen');

sim.addElement(Preprocessing('preprocessing'));
sim.addConnection('targetImage','imageRed','preprocessing');
sim.addConnection('targetImage','imageGreen','preprocessing');
sim.addConnection('nodeRed','output','preprocessing');
sim.addConnection('nodeGreen','output','preprocessing');

sim.addElement(NeuralField('targetLocationMap', fieldSize, 20, -1, 4));
sim.addConnection('preprocessing','output','targetLocationMap');

threshold=-5;

sim.addElement(ModifiedHand2D('hand', fieldSize, 15,15, (-1*threshold), fieldSize(:,1)/2, fieldSize(:,2)/2));
sim.addElement(ModifiedGaussStimulus2D('fixedStimuli', fieldSize, 15, 15, (-1*threshold), fieldSize(:,1)/2, fieldSize(:,2)/2));
sim.addElement(ModifiedConvolution('handTargetDifferenceMap', fieldSize , 1 ,0,9.3), {'hand', 'targetLocationMap'},{'output','output'});

% add field d
sim.addElement(NeuralField('field d', fieldSize, 20, threshold, 4),{'fixedStimuli','handTargetDifferenceMap'},{'output','output'});
sim.addElement(ModifiedNeuralField('velocityMap', fieldSize, 5, (threshold+4.8), 4));

% there is no local inhibition from d to d
sim.addElement(LateralInteractions2D('d -> d', fieldSize, sigmaExcY,sigmaExcX, amplitudeExc, sigmaInhY, sigmaInhX, 0, amplitudeGlobal_dd), 'field d', 'output', 'field d');
sim.addElement(LateralInteractions2D('d -> v', fieldSize, sigmaExcY,sigmaExcX, amplitudeExc, sigmaInhY, sigmaInhX, amplitudeInh_dv, amplitudeGlobal_dv), 'field d', 'output', 'velocityMap');

sim.addElement(NormalNoise('noise u', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel u', fieldSize, 5, 5, 0.2, true, true), 'noise u', 'output', 'field d');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel2D('noise kernel v', fieldSize, 5, 5, 0.2, true, true), 'noise v', 'output', 'velocityMap');


sim.addElement(ScaleInput('c_21', [1, 1]), 'nodeRed', 'output', 'nodeGreen');
sim.addElement(ScaleInput('c_12', [1, 1]), 'nodeGreen', 'output', 'nodeRed');

sim.addElement(RunningHistory('historyRedNodeActivation', [1, 1], historyDuration, 1), 'nodeRed', 'activation');
sim.addElement(RunningHistory('historyRedNodeOutput', [1, 1], historyDuration, 1), 'nodeRed', 'output'); % This added
sim.addElement(RunningHistory('historyGreenNodeActivation', [1, 1], historyDuration, 1), 'nodeGreen', 'activation');
sim.addElement(RunningHistory('historyGreenNodeOutput', [1, 1], historyDuration, 1), 'nodeGreen', 'output');

sim.addElement(SumInputs('shiftedStimulusRed', [1, 1]), {'targetImage', 'nodeRed'}, {'inputForRed', 'h'});
sim.addElement(SumInputs('shiftedStimulusGreen', [1, 1]), {'targetImage', 'nodeGreen'}, {'inputForGreen', 'h'});

sim.addElement(RunningHistory('stimulusHistoryRed', [1, 1], historyDuration, 1), 'shiftedStimulusRed');
sim.addElement(RunningHistory('stimulusHistoryGreen', [1, 1], historyDuration, 1), 'shiftedStimulusGreen');


%% setting up the GUI
elementGroups = {'nodeRed', 'nodeGreen','velocityMap','d -> d','d -> v'};

gui = StandardGUI(sim, [50, 50, 1020, 500], 0, [0.0, 0.0, 0.75, 1.0], [4, 3], [0.03, 0.05], ...
    [0.75, 0.0, 0.25, 1.0], [20, 2], elementGroups, elementGroups);


gui.addVisualization(MultiPlot({'nodeRed', 'stimulusHistoryRed', 'historyRedNodeActivation','historyRedNodeOutput'}, {'activation', 'output','output','output'}, ...
    [1, 1, 1, 1], 'horizontal', ...
    {'FontSize',15,'XLim', [-historyDuration, 10], 'YLim', [-10, 15], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1}, ...
    {'b-', 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1}, {'r-', 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1} }, ...
    'Target Colour Map (Red Node)', 'relative time', 'activation','output'), [1, 2]);
gui.addVisualization(MultiPlot({'nodeGreen', 'stimulusHistoryGreen', 'historyGreenNodeActivation','historyGreenNodeOutput'}, {'activation', 'output', 'output','output'}, ...
    [1, 1, 1, 1], 'horizontal', ...
    {'FontSize',15,'XLim', [-historyDuration, 10], 'YLim', [-10, 15], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
    { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1}, ...
    {'b-', 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1}, {'r-', 'LineWidth', 3, 'XData', 0:-1:-historyDuration+1}},...
    'Target Colour Map (Green Node)', 'relative time', 'activation','output'), [2.1, 2]);

gui.addVisualization(RGBImage('targetImage', 'image', {'FontSize',15,'XTick', [], 'YTick', []}, {},'\fontsize{15}Current Target Image'), [1, 1], [1, 1]);
gui.addVisualization(ScaledImage('hand', 'output',[4.5, 5],{'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Hand Map'), [2, 1],[1, 1]);
gui.addVisualization(ScaledImage('fixedStimuli', 'output',[0, 10],{'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Fixed Stimuli'), [3, 1],[1, 1]);
gui.addVisualization(ScaledImage('field d', 'output',[0, 1],{'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Hand-Target Difference Map (D) Output'), [4, 1],[1, 1]);

%gui.addVisualization(ExtendedRGBImage('targetImage', 'image','hand','positionX','positionY', {'FontSize',15,'XTick', [], 'YTick', []}, {},{'LineWidth',4},'\fontsize{15}Hand Trajectory'), [3.5, 2], [1.5, 1]);

gui.addVisualization(ScaledImage('targetLocationMap', 'activation',[0, 10],{'FontSize',15,'XTick', [], 'YTick', []},{}, {'\fontsize{15}Target Location Map Activation'}), [1, 3],[1, 1]);
gui.addVisualization(ScaledImage('targetLocationMap', 'output',[0, 1], {'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Target Location Map Output'), [2, 3],[1, 1]);
gui.addVisualization(ScaledImage('handTargetDifferenceMap', 'output',[0, 10], {'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Hand-Target Difference (Convolution)'), [3, 3],[1, 1]);
gui.addVisualization(ScaledImage('velocityMap', 'output',[0, 1], {'FontSize',15,'XTick', [], 'YTick', []},{}, '\fontsize{15}Velocity Map (V) Output'), [4, 3],[1, 1]);


gui.addControl(ParameterSlider('h_Red', 'nodeRed', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u_1'), [1, 1],[1.2,1]);
gui.addControl(ParameterSlider('q_Red', 'nodeRed', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u_1'), [2.2, 1],[1.2,1]);
gui.addControl(ParameterSlider('c_R-R', 'nodeRed', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_1 to itself'), [3.4, 1],[1.2,1]);
gui.addControl(ParameterSlider('c_R<G', 'c_12', 'amplitude', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_2 to node u_1'), [4.6, 1]);

gui.addControl(ParameterSlider('h_Green', 'nodeGreen', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u'), [8, 1]);
gui.addControl(ParameterSlider('q_Green', 'nodeGreen', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u'), [9, 1]);
gui.addControl(ParameterSlider('c_G-G', 'nodeGreen', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_2 to itself'), [10, 1]);
gui.addControl(ParameterSlider('c_G<R', 'c_21', 'amplitude', [-10, 10], '%0.1f', 1, ...
    'connection strength from node u_1 to node u_2'), [11, 1]);

% gui.addControl(ParameterSlider('dInhAmp', 'd -> d', 'amplitudeInh', [0, 20], '%0.1f', 1, ...
%   'strength of local inhibition in field d'), [14, 1]);
gui.addControl(ParameterSlider('dExc', 'd -> d', 'amplitudeExc', [0, 20], '%0.1f', 1, ...
    'strength of lateral excitation in field d'), [15, 1]);
gui.addControl(ParameterSlider('dGlobInh', 'd -> d', 'amplitudeGlobal', [-0.1, 0], '%0.3f', 1, ...
    'strength of global inhibition in field d'), [16, 1]);

gui.addControl(ParameterSlider('d-vExc', 'd -> v', 'amplitudeExc', [0, 20], '%0.1f', 1, ...
    'strength of lateral excitation in d -> v'), [18, 1]);
gui.addControl(ParameterSlider('d-vInh', 'd -> v', 'amplitudeInh', [0, 20], '%0.1f', 1, ...
    'strength of lateral excitation in d -> v'), [19, 1]);
gui.addControl(ParameterSlider('d-vGlobInh', 'd -> v', 'amplitudeGlobal', [-0.1, 0], '%0.3f', 1, ...
    'strength of lateral excitation in d -> v'), [20, 1]);


% Slider controls for the hand map and hand-target difference map
gui.addControl(ParameterSlider('handX', 'hand', 'positionX', [0, fieldSize(:,1)], '%0.1f', 1, 'hand position on X-axis'), [1, 2],[1, 1]);
gui.addControl(ParameterSlider('handY', 'hand', 'positionY', [0, fieldSize(:,2)], '%0.1f', 1, 'hand position on Y-axis'), [2, 2],[1, 1]);
gui.addControl(ParameterSlider('handAmp', 'hand', 'amplitude', [0, 10], '%0.1f', 1, 'hand stimuli amplitude'), [3, 2],[1, 1]);
gui.addControl(ParameterSlider('HT_Conv', 'handTargetDifferenceMap', 'handAmplitude', [0, 10], '%0.1f', 1, 'handTargetMap stimuli amplitude'), [4, 2],[1, 1]);
gui.addControl(ParameterSlider('hVarX', 'hand', 'sigmaX', [0, 30], '%0.1f', 1, 'hand stimuli variance X'), [5, 2],[1, 1]);
gui.addControl(ParameterSlider('hVarY', 'hand', 'sigmaY', [0, 30], '%0.1f', 1, 'hand stimuli variance Y'), [6, 2],[1, 1]);

% Slider controls for the fixed stimuli
gui.addControl(ParameterSlider('fixStim', 'fixedStimuli', 'amplitude', [0, 10], '%0.1f', 1, 'fixed stimuli amplitude'), [8, 2]);
gui.addControl(ParameterSlider('FS_VarX', 'fixedStimuli', 'sigmaX', [0, 30], '%0.1f', 1, 'fixed stimuli variance X'), [9, 2]);
gui.addControl(ParameterSlider('FS_VarY', 'fixedStimuli', 'sigmaY', [0, 30], '%0.1f', 1, 'fixed stimuli variance Y'), [10, 2]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [15, 2]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [16, 2]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [17, 2]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [18, 2]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [19, 2]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [20, 2]);

gui.run(inf);





