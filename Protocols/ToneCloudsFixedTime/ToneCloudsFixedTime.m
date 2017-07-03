
function ToneCloudsFixedTime

% This protocol implements the fixed time version of ToneClouds (developed by P. Znamenskiy) on Bpod
% Based on PsychoToolboxSound (written by J.Sanders)

% Written by F.Carnevale, 2/2015.

global BpodSystem

addpath(genpath('/home/rig7/PulsePal'));

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        
    S.GUI.Subject.panel = 'Protocol'; S.GUI.Subject.style = 'text'; S.GUI.Subject.string = BpodSystem.GUIData.SubjectName;    
    S.GUI.Stage.panel = 'Protocol'; S.GUI.Stage.style = 'popupmenu'; S.GUI.Stage.string = {'Direct', 'Full 1', 'Full 2', 'Full 3', 'Full 4', 'Full 5', 'Full 6'}; S.GUI.Stage.value = 2;% Training stage
    
    % Stimulus section
    S.GUI.VolumeMin.panel = 'Stimulus settings'; S.GUI.VolumeMin.style = 'edit'; S.GUI.VolumeMin.string = 50; % Lowest volume dB
    S.GUI.VolumeMax.panel = 'Stimulus settings'; S.GUI.VolumeMax.style = 'edit'; S.GUI.VolumeMax.string = 60; % Highest Volume dB
    S.GUI.DifficultyLow.panel = 'Stimulus settings'; S.GUI.DifficultyLow.style = 'edit'; S.GUI.DifficultyLow.string = 1; % Lowest difficulty
    S.GUI.DifficultyHigh.panel = 'Stimulus settings'; S.GUI.DifficultyHigh.style = 'edit'; S.GUI.DifficultyHigh.string = 1; % Highest difficulty
    S.GUI.nDifficulties.panel = 'Stimulus settings'; S.GUI.nDifficulties.style = 'edit'; S.GUI.nDifficulties.string = 0; % Number of difficulties
    S.GUI.ToneOverlap.panel = 'Stimulus settings'; S.GUI.ToneOverlap.style = 'edit'; S.GUI.ToneOverlap.string = 0.66; % Overlap between tones (0 to 1) 0 meaning no overlap
    S.GUI.ToneDuration.panel = 'Stimulus settings'; S.GUI.ToneDuration.style = 'edit'; S.GUI.ToneDuration.string = 0.030;
    S.GUI.NoEvidence.panel = 'Stimulus settings'; S.GUI.NoEvidence.style = 'edit'; S.GUI.NoEvidence.string = 0; % Number of tones with no evidence
    S.GUI.AudibleHuman.panel = 'Stimulus settings'; S.GUI.AudibleHuman.style = 'checkbox'; S.GUI.AudibleHuman.string = 'Audible'; S.GUI.AudibleHuman.value = 0;    
    
    % Reward 
    S.GUI.CenterRewardAmount.panel = 'Reward settings'; S.GUI.CenterRewardAmount.style = 'edit'; S.GUI.CenterRewardAmount.string = 0.5;
    S.GUI.RewardAmount.panel = 'Reward settings'; S.GUI.RewardAmount.style = 'edit'; S.GUI.RewardAmount.string = 2.5;
    S.GUI.FreqSide.panel = 'Reward settings'; S.GUI.FreqSide.style = 'popupmenu'; S.GUI.FreqSide.string = {'LowLeft', 'LowRight'}; S.GUI.FreqSide.value = 1;% Training stage
    S.GUI.PunishSound.panel = 'Reward settings'; S.GUI.PunishSound.style = 'checkbox'; S.GUI.PunishSound.string = 'Active';  S.GUI.PunishSound.value = 0;
    
    % Trial structure section     
    S.GUI.TimeForResponse.panel = 'Trial Structure'; S.GUI.TimeForResponse.style = 'edit'; S.GUI.TimeForResponse.string = 10;
    S.GUI.TimeoutDuration.panel = 'Trial Structure'; S.GUI.TimeoutDuration.style = 'edit'; S.GUI.TimeoutDuration.string = 4;    
    
    S.GUI.PrestimDistribution.panel = 'Prestim Timing'; S.GUI.PrestimDistribution.style = 'popupmenu'; S.GUI.PrestimDistribution.string = {'Delta', 'Uniform', 'Exponential'}; S.GUI.PrestimDistribution.value = 1;% Training stage
    S.GUI.PrestimDurationStart.panel = 'Prestim Timing'; S.GUI.PrestimDurationStart.style = 'edit'; S.GUI.PrestimDurationStart.string = 0.050; % Prestim duration start
    S.GUI.PrestimDurationEnd.panel = 'Prestim Timing'; S.GUI.PrestimDurationEnd.style = 'edit'; S.GUI.PrestimDurationEnd.string = 0.050; % Prestim duration end
    S.GUI.PrestimDurationStep.panel = 'Prestim Timing'; S.GUI.PrestimDurationStep.style = 'edit'; S.GUI.PrestimDurationStep.string = 0.050; % Prestim duration end
    S.GUI.PrestimDurationNtrials.panel = 'Prestim Timing'; S.GUI.PrestimDurationNtrials.style = 'edit'; S.GUI.PrestimDurationNtrials.string = 20; % Required number of valid trials before each step    
    S.GUI.PrestimDurationCurrent.panel = 'Prestim Timing'; S.GUI.PrestimDurationCurrent.style = 'text'; S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationStart.string; % Prestim duration end    
    
    S.GUI.SoundDurationStart.panel = 'Stimulus Timing'; S.GUI.SoundDurationStart.style = 'edit'; S.GUI.SoundDurationStart.string = 0.1; % Sound duration start
    S.GUI.SoundDurationEnd.panel = 'Stimulus Timing'; S.GUI.SoundDurationEnd.style = 'edit'; S.GUI.SoundDurationEnd.string = 0.500; % Sound duration end
    S.GUI.SoundDurationStep.panel = 'Stimulus Timing'; S.GUI.SoundDurationStep.style = 'edit'; S.GUI.SoundDurationStep.string = 0.1; % Sound duration step
    S.GUI.SoundDurationNtrials.panel = 'Stimulus Timing'; S.GUI.SoundDurationNtrials.style = 'edit'; S.GUI.SoundDurationNtrials.string = 20; % Required number of valid trials before each step
    S.GUI.SoundDurationCurrent.panel = 'Stimulus Timing'; S.GUI.SoundDurationCurrent.style = 'text'; S.GUI.SoundDurationCurrent.string = S.GUI.SoundDurationStart.string; % Sound duration end
    
    S.GUI.MemoryDurationStart.panel = 'Memory Timing'; S.GUI.MemoryDurationStart.style = 'edit'; S.GUI.MemoryDurationStart.string = 0; % Memory duration start
    S.GUI.MemoryDurationEnd.panel = 'Memory Timing'; S.GUI.MemoryDurationEnd.style = 'edit'; S.GUI.MemoryDurationEnd.string = 0; % Memory duration end
    S.GUI.MemoryDurationStep.panel = 'Memory Timing'; S.GUI.MemoryDurationStep.style = 'edit'; S.GUI.MemoryDurationStep.string = 0.010; % Memory duration end
    S.GUI.MemoryDurationNtrials.panel = 'Memory Timing'; S.GUI.MemoryDurationNtrials.style = 'edit'; S.GUI.MemoryDurationNtrials.string = 20; % Required number of valid trials before each step
    S.GUI.MemoryDurationCurrent.panel = 'Memory Timing'; S.GUI.MemoryDurationCurrent.style = 'text'; S.GUI.MemoryDurationCurrent.string = S.GUI.MemoryDurationStart.string; % Memory duration end
    
    S.GUI.OptoOn.panel = 'Optogenetic'; S.GUI.OptoOn.style = 'checkbox'; S.GUI.OptoOn.string = 'On'; S.GUI.OptoOn.value = 1; 
    S.GUI.OptoProb.panel = 'Optogenetic'; S.GUI.OptoProb.style = 'edit'; S.GUI.OptoProb.string = 0.20;
    S.GUI.OptoPulseFreq.panel = 'Optogenetic'; S.GUI.OptoPulseFreq.style = 'edit'; S.GUI.OptoPulseFreq.string = 10;
    S.GUI.OptoPulseWidth.panel = 'Optogenetic'; S.GUI.OptoPulseWidth.style = 'edit'; S.GUI.OptoPulseWidth.string = 2;
    S.GUI.OptoOnset.panel = 'Optogenetic'; S.GUI.OptoOnset.style = 'edit'; S.GUI.OptoOnset.string = 0;
    S.GUI.OptoOffset.panel = 'Optogenetic'; S.GUI.OptoOffset.style = 'edit'; S.GUI.OptoOffset.string = 0.5;
        
    % Antibias
    S.GUI.Antibias.panel = 'Antibias'; S.GUI.Antibias.style = 'popupmenu'; S.GUI.Antibias.string = {'no', 'yes'}; S.GUI.Antibias.value = 1;% Training stage
    
    if S.GUI.AudibleHuman.value, minFreq = 200; maxFreq = 2000; else minFreq = 5000; maxFreq = 40000; end

    % Other Stimulus settings (not in the GUI)
    StimulusSettings.ToneOverlap = S.GUI.ToneOverlap.string;
    StimulusSettings.ToneDuration = S.GUI.ToneDuration.string;
    StimulusSettings.minFreq = minFreq;
    StimulusSettings.maxFreq = maxFreq;
    StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
    StimulusSettings.Noevidence = S.GUI.NoEvidence.string;   
    StimulusSettings.nFreq = 18; % Number of different frequencies to sample from
    StimulusSettings.ramp = 0.005;     
end

%% Define trials
MaxTrials = 5000;
TrialTypes = ceil(rand(1,MaxTrials)*2); % correct side for each trial
EvidenceStrength = nan(1,MaxTrials); % evidence strength for each trial
pTarget = nan(1,MaxTrials); % evidence strength for each trial
PrestimDuration = nan(1,MaxTrials); % prestimulation delay period for each trial
SoundDuration = nan(1,MaxTrials); % sound duration period for each trial
MemoryDuration = nan(1,MaxTrials); % memory duration period for each trial
Outcomes = nan(1,MaxTrials);
Side = nan(1,MaxTrials);
OptoTrial = zeros(1,MaxTrials);
OptoSettings = cell(1,MaxTrials);
AccumulatedReward=0;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.EvidenceStrength = []; % The evidence strength of each trial completed will be added here.
BpodSystem.Data.PrestimDuration = []; % The evidence strength of each trial completed will be added here.

%% Initialize plots

% Initialize parameter GUI plugin
EnhancedBpodParameterGUI('init', S);

% Outcome plot
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [457 803 1000 250],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',2-TrialTypes);

% Notebook
BpodNotebook('init');

% Performance
BpodSystem.ProtocolFigures.PerformancePlotFig = figure('Position', [455 595 1000 250],'name','Performance plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.PerformancePlot = axes('Position', [.075 .3 .79 .6]);
PerformancePlot(BpodSystem.GUIHandles.PerformancePlot,'init')  %set up axes nicely

% Psychometric
BpodSystem.ProtocolFigures.PsychoPlotFig = figure('Position', [1450 100 400 300],'name','Pshycometric plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.PsychoPlot = axes('Position', [.2 .25 .75 .65]);
PsychoPlot(BpodSystem.GUIHandles.PsychoPlot,'init')  %set up axes nicely


% % BinoPlot
% BpodSystem.ProtocolFigures.BinoPlotFig = figure('Position', [1450 100 400 300],'name','Binomial plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
% BpodSystem.GUIHandles.BinoPlot = axes('Position', [.2 .25 .75 .65]);
% hold(BpodSystem.GUIHandles.BinoPlot,'on')
% BinoPlot(BpodSystem.GUIHandles.BinoPlot,'init',2)  %set up axes nicely

% Stimulus plot
BpodSystem.ProtocolFigures.StimulusPlotFig = figure('Position', [457 803 500 300],'name','Stimulus plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.StimulusPlot = axes('Position', [.15 .2 .75 .65]);
StimulusPlot(BpodSystem.GUIHandles.StimulusPlot,'init',StimulusSettings.nFreq);



%%% Pokes plot
state_colors = struct( ...
        'WaitForCenterPoke', [0.5 0.5 1],...
        'Delay',0.3*[1 1 1],...
        'DeliverStimulus', 0.75*[1 1 0],...
        'Memory', 0.75*[0.25 1 0.5],...
        'GoSignal',[0.5 1 1],...        
        'Reward',[0,1,0],...
        'Drinking',[0,0,1],...
        'Punish',[1,0,0],...
        'EarlyWithdrawal',[1,0.3,0],...
        'EarlyWithdrawalPunish',[1,0,0],...
        'WaitForResponse',0.75*[0,1,1],...
        'CorrectWithdrawalEvent',[1,0,0],...
        'exit',0.2*[1 1 1]);
    
poke_colors = struct( ...
      'L', 0.6*[1 0.66 0], ...
      'C', [0 0 0], ...
      'R',  0.9*[1 0.66 0]);
    
PokesPlot('init', state_colors,poke_colors);

%% Repositionate GUI's
BpodSystem.GUIHandles.MainFig.Position = [389 92 BpodSystem.GUIHandles.MainFig.Position(3:4)];
BpodSystem.ProtocolFigures.Notebook.Position = [229 -1.5 BpodSystem.ProtocolFigures.Notebook.Position(3:4)];
BpodSystem.ProtocolFigures.BpodParameterGUI.Position = [66 1 BpodSystem.ProtocolFigures.BpodParameterGUI.Position(3:4)];
BpodSystem.ProtocolFigures.PerformancePlotFig.Position = [705 533 BpodSystem.ProtocolFigures.PerformancePlotFig.Position(3:4)];
BpodSystem.ProtocolFigures.OutcomePlotFig.Position = [705 832 BpodSystem.ProtocolFigures.OutcomePlotFig.Position(3:4)];
BpodSystem.ProtocolFigures.PsychoPlotFig.Position = [1196 193 BpodSystem.ProtocolFigures.PsychoPlotFig.Position(3:4)];

%% Define stimuli and send to sound server

SF = StimulusSettings.SamplingRate;
PunishSound = (rand(1,SF*.5)*2) - 1;
% Generate early withdrawal sound
W1 = GenerateSineWave(SF, 1000, .5); W2 = GenerateSineWave(SF, 1200, .5); EarlyWithdrawalSound = W1+W2;
P = SF/100; Interval = P;
for x = 1:50
    EarlyWithdrawalSound(P:P+Interval) = 0;
    P = P+(Interval*2);
end

% Program sound server
PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 3, PunishSound);
PsychToolboxSoundServer('Load', 4, EarlyWithdrawalSound);


%Set up pulse pal for optogenetic stimulation
try
    PulsePal;
    pulsepal_connected = 1;
catch
    disp('No PulsePal connected');
    pulsepal_connected = 0;
end

if pulsepal_connected
    load ParameterMatrix_Example;
    ProgramPulsePal(ParameterMatrix); % Sends the default parameter matrix to Pulse Pal
    ProgramPulsePalParam(1, 'LinkedToTriggerCH1', 0);
    ProgramPulsePalParam(2, 'LinkedToTriggerCH1', 0);
    ProgramPulsePalParam(3, 'LinkedToTriggerCH1', 0);
    ProgramPulsePalParam(4, 'LinkedToTriggerCH1', 1); % Set output channel 4 to respond to trigger ch 1
end

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'ToneCloud Protocol...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

% Disable changing task 
BpodSystem.GUIHandles.ParameterGUI.ParamValues(strcmp(BpodSystem.GUIHandles.ParameterGUI.ParamNames,'Stage')==1).Enable = 'off';

% Set timer for this session
SessionBirthdate = tic;

CenterValveCode = 2;

% Control the step up of prestimulus period and stimulus duration
controlStep_Prestim = 0; % valid trial counter
controlStep_Sound = 0; % valid trial counter
controlStep_Memory = 0; % valid trial counter

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
        
    if S.GUI.AudibleHuman.value, minFreq = 200; maxFreq = 2000; else minFreq = 5000; maxFreq = 40000; end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Prestimulation Duration

    if currentTrial==1 %start from the start
        S.GUI.PrestimDurationCurrent.string =  S.GUI.PrestimDurationStart.string;
    end    
    controlStep_nRequiredValid_Prestim = S.GUI.PrestimDurationNtrials.string;    
    
    if S.GUI.PrestimDurationStart.string<S.GUI.PrestimDurationEnd.string %step up prestim duration only if start<end
        if S.GUI.SoundDurationCurrent.string >= S.GUI.SoundDurationEnd.string % step up prestim only if stimulus is already at end duration

            if controlStep_Prestim > controlStep_nRequiredValid_Prestim

                controlStep_Prestim = 0; %restart counter

                % step up, unless we are at the max
                if S.GUI.PrestimDurationCurrent.string + S.GUI.PrestimDurationStep.string > S.GUI.PrestimDurationEnd.string
                    S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationEnd.string;
                else
                    S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationCurrent.string + S.GUI.PrestimDurationStep.string;
                end
            end
        end
    else
       S.GUI.PrestimDurationCurrent.string =  S.GUI.PrestimDurationStart.string;
    end    
    
    
    switch S.GUI.PrestimDistribution.value
        case 1
            PrestimDuration(currentTrial) = S.GUI.PrestimDurationCurrent.string;
        case 2
            % uniform distribution with mean = range
            PrestimDuration(currentTrial) = (rand+0.5)*S.GUI.PrestimDurationCurrent.string;
        case 3
            PrestimDuration(currentTrial) = exprnd(S.GUI.PrestimDurationCurrent.string);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Sound Duration
    
    if currentTrial ==1 % start from the start
        S.GUI.SoundDurationCurrent.string =  S.GUI.SoundDurationStart.string;
    end
    controlStep_nRequiredValid_Sound = S.GUI.SoundDurationNtrials.string;
    
    if S.GUI.SoundDurationStart.string<S.GUI.SoundDurationEnd.string %step up sound duration only if start<end
        if controlStep_Sound > controlStep_nRequiredValid_Sound

            controlStep_Sound = 0; %restart counter

            % step up, unless we are at the max
            if S.GUI.SoundDurationCurrent.string + S.GUI.SoundDurationStep.string > S.GUI.SoundDurationEnd.string
                S.GUI.SoundDurationCurrent.string = S.GUI.SoundDurationEnd.string;
            else
                S.GUI.SoundDurationCurrent.string = S.GUI.SoundDurationCurrent.string + S.GUI.SoundDurationStep.string;
            end
        end
    else
       S.GUI.SoundDurationCurrent.string =  S.GUI.SoundDurationStart.string;
    end
        
    SoundDuration(currentTrial) = S.GUI.SoundDurationCurrent.string;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MemoryDuration
    
    if currentTrial ==1 % start from the start
        S.GUI.MemoryDurationCurrent.string =  S.GUI.MemoryDurationStart.string;
    end
    controlStep_nRequiredValid_Memory = S.GUI.MemoryDurationNtrials.string;
    
    if S.GUI.MemoryDurationStart.string<S.GUI.MemoryDurationEnd.string %step up memory duration only if start<end
        if controlStep_Memory > controlStep_nRequiredValid_Memory

            controlStep_Memory = 0; %restart counter

            % step up, unless we are at the max
            if S.GUI.MemoryDurationCurrent.string + S.GUI.MemoryDurationStep.string > S.GUI.MemoryDurationEnd.string
                S.GUI.MemoryDurationCurrent.string = S.GUI.MemoryDurationEnd.string;
            else
                S.GUI.MemoryDurationCurrent.string = S.GUI.MemoryDurationCurrent.string + S.GUI.MemoryDurationStep.string;
            end
        end
    else
       S.GUI.MemoryDurationCurrent.string =  S.GUI.MemoryDurationStart.string;
    end
        
    MemoryDuration(currentTrial) = S.GUI.MemoryDurationCurrent.string;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    R = GetValveTimes(S.GUI.RewardAmount.string, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    C = GetValveTimes(S.GUI.CenterRewardAmount.string, 2); CenterValveTime = C(1);

    
    % Update stimulus settings
    StimulusSettings.nTones = floor((S.GUI.SoundDurationCurrent.string-S.GUI.ToneDuration.string*S.GUI.ToneOverlap.string)/(S.GUI.ToneDuration.string*(1-S.GUI.ToneOverlap.string)));
    StimulusSettings.ToneOverlap = S.GUI.ToneOverlap.string;
    StimulusSettings.ToneDuration = S.GUI.ToneDuration.string;
    StimulusSettings.minFreq = minFreq;
    StimulusSettings.maxFreq = maxFreq;
    StimulusSettings.Noevidence = S.GUI.NoEvidence.string;   
    StimulusSettings.VolumeMin = S.GUI.VolumeMin.string;
    StimulusSettings.VolumeMax = S.GUI.VolumeMax.string;
    
    StimulusSettings.Volume = (randi(10)-1)/4*(StimulusSettings.VolumeMax-StimulusSettings.VolumeMin) + StimulusSettings.VolumeMin;
    
    
    bias = nanmean(Side(1:currentTrial-1))-1; %0:left, 1:right
    disp(['Bias (0:left,1:right): ' num2str(bias)]);
    if S.GUI.Antibias.value==2 %apply antib;ias
        
        if rand<bias % this condition is met most frequently when bias is close to 1 (bias is to the right)
            TrialTypes(currentTrial) = 1; % type 1 means reward at left 
        else % this condition is most frequently met when bias is close to 0 (bias to the left) 
            TrialTypes(currentTrial) = 2; % type 2 means reward at right 
        end
    end

    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        
        case 1 % Left is rewarded
            
            if strcmp(S.GUI.FreqSide.string(S.GUI.FreqSide.value),'LowLeft')                
                TargetOctave = 'low';
            else
                TargetOctave = 'high';
            end
            
            LeftActionState = 'Reward'; RightActionState = 'Punish'; CorrectWithdrawalEvent = 'Port1Out';
            ValveCode = 1; ValveTime = LeftValveTime;
            RewardedPort = {'Port1In'};PunishedPort = {'Port3In'};
            
        case 2 % Right is rewarded
            
            if strcmp(S.GUI.FreqSide.string(S.GUI.FreqSide.value),'LowRight')                
                TargetOctave = 'low';
            else
                TargetOctave = 'high';
            end
            
            LeftActionState = 'Punish'; RightActionState = 'Reward'; CorrectWithdrawalEvent = 'Port3Out';
            ValveCode = 4; ValveTime = RightValveTime;
            RewardedPort = {'Port3In'}; PunishedPort = {'Port1In'};
    end
    
    if S.GUI.PunishSound.value
        PsychToolboxSoundServer('Load', 3, PunishSound);
        PsychToolboxSoundServer('Load', 4, EarlyWithdrawalSound);
    else
        PsychToolboxSoundServer('Load', 3, 0);
        PsychToolboxSoundServer('Load', 4, 0);
    end
    
    
    switch 1
        
        case strcmp(S.GUI.Stage.string(S.GUI.Stage.value),'Direct') % Training stage 1: Direct sides - Poke and collect water
            
            S.GUI.DifficultyLow.enable = 'off';
            S.GUI.DifficultyHigh.enable = 'off';
            S.GUI.nDifficulties.enable = 'off';

            S.GUI.TimeoutDuration.string = 0;
            S.GUI.TimeoutDuration.enable = 'off';
            
            EvidenceStrength(currentTrial) = 1;            
            
            % This stage sound generation
            [Sound, Cloud, Cloud_toplot] = GenerateToneCloud(TargetOctave, EvidenceStrength(currentTrial), StimulusSettings);
            PsychToolboxSoundServer('Load', 1, Sound);
            
            
            sma = NewStateMatrix(); % Assemble state matrix
            
            sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port2In', 'Delay'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Delay', ...
                'Timer', PrestimDuration(currentTrial),...
                'StateChangeConditions', {'Tup', 'DeliverStimulus'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DeliverStimulus', ...
                'Timer', SoundDuration(currentTrial),...
                'StateChangeConditions', {'Tup', 'GoSignal', 'Port2Out', 'EarlyWithdrawal'},...
                'OutputActions', {'SoftCode', 1, 'BNCState', 1}); 
            sma = AddState(sma, 'Name', 'GoSignal', ...
                'Timer', CenterValveTime,...
                'StateChangeConditions', {'Tup', 'Reward'},...
                'OutputActions', {'ValveState', CenterValveCode});
            sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'Punish'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', ValveCode});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0.01,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
            
            SendStateMatrix(sma);
            RawEvents = RunStateMatrix;     
            
        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Full') % Full task
                        
  
            switch 1

                case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'1')
                % Full 1: no punish sound, no timeout, sound duration ramping up in 40 trials, prestim 0.05 delta 
                % (until it does reasonable number of trials)

                    S.GUI.PunishSound.value = 0;
                    S.GUI.TimeoutDuration.string = 0;
                    S.GUI.SoundDurationNtrials.string = 40;
                    S.GUI.PrestimDistribution.value = 1;
                    S.GUI.PrestimDurationEnd.string = 0.050; % Prestim duration end
    
                case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'2')
                % Full 2: punish sound, 4s timeout, sound duration ramping up in 20 trials, prestim 0.1 uniform 
                % (until gets the association)
            
                    S.GUI.PunishSound.value = 1;
                    S.GUI.TimeoutDuration.string = 4;
                    S.GUI.SoundDurationNtrials.string = 20;
                    S.GUI.PrestimDistribution.value = 2;
                    S.GUI.PrestimDurationEnd.string = 0.10; % Prestim duration end
                    S.GUI.PrestimDurationNtrials.string = 20; % Required number of valid trials before each step    
             
                case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'3')
                % Full 3: sound duration ramping up 2 trials, prestim 0.25 uniform
                % (until the end, increasing difficulty)
                
                    S.GUI.PunishSound.value = 1;
                    S.GUI.TimeoutDuration.string = 4;
                    S.GUI.SoundDurationNtrials.string = 2;
                    S.GUI.PrestimDistribution.value = 2;
                    S.GUI.PrestimDurationEnd.string = 0.25; % Prestim duration end
                    S.GUI.PrestimDurationNtrials.string = 2; % Required number of valid trials before each step    

               case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'4')
                % Full 4: lower diff= 0.7, n_diff=3
                
                    S.GUI.PunishSound.value = 1;
                    S.GUI.TimeoutDuration.string = 4;
                    S.GUI.SoundDurationNtrials.string = 2;
                    S.GUI.PrestimDistribution.value = 2;
                    S.GUI.PrestimDurationEnd.string = 0.25; % Prestim duration end
                    S.GUI.PrestimDurationNtrials.string = 2; % Required number of valid trials before each step    

                    S.GUI.DifficultyLow.string = 0.7; % Lowest difficulty
                    S.GUI.nDifficulties.string = 3;
                    
               case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'5')
                % Full 5: lower diff= 0.5, n_diff=3
                
                    S.GUI.PunishSound.value = 1;
                    S.GUI.TimeoutDuration.string = 4;
                    S.GUI.SoundDurationNtrials.string = 2;
                    S.GUI.PrestimDistribution.value = 2;
                    S.GUI.PrestimDurationEnd.string = 0.25; % Prestim duration end
                    S.GUI.PrestimDurationNtrials.string = 2; % Required number of valid trials before each step    

                    S.GUI.DifficultyLow.string = 0.5; % Lowest difficulty
                    S.GUI.nDifficulties.string = 5;
                    
               case strfind(S.GUI.Stage.string{S.GUI.Stage.value}(6),'6')
                % Full 6: lower diff= 0.3, n_diff=5
                
                    S.GUI.PunishSound.value = 1;
                    S.GUI.TimeoutDuration.string = 4;
                    S.GUI.SoundDurationNtrials.string = 2;
                    S.GUI.PrestimDistribution.value = 2;
                    S.GUI.PrestimDurationEnd.string = 0.25; % Prestim duration end
                    S.GUI.PrestimDurationNtrials.string = 2; % Required number of valid trials before each step    

                    S.GUI.DifficultyLow.string = 0.3; % Lowest difficulty
                    S.GUI.nDifficulties.string = 5;
            end
            
            S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
            
            DifficultySet = [S.GUI.DifficultyLow.string S.GUI.DifficultyLow.string:(S.GUI.DifficultyHigh.string-S.GUI.DifficultyLow.string)/(S.GUI.nDifficulties.string-1):S.GUI.DifficultyHigh.string S.GUI.DifficultyHigh.string];
            DifficultySet = unique(DifficultySet);

            EvidenceStrength(currentTrial) = DifficultySet(randi(size(DifficultySet,2)));
            
            % This stage sound generation
            [Sound, Cloud, Cloud_toplot] = GenerateToneCloud(TargetOctave, EvidenceStrength(currentTrial), StimulusSettings);
            PsychToolboxSoundServer('Load', 1, Sound);
            
            % Because stimulus generation is random, we need to check trial
            % by trial, so that the animal is rewarded by what they hear
            if sum(Cloud>9)>sum(Cloud<9) % if more high than low tones
                
                pTarget(currentTrial) = sum(Cloud>9)/sum(Cloud>0);
                            
                TargetOctave = 'high';

                if strcmp(S.GUI.FreqSide.string(S.GUI.FreqSide.value),'LowLeft')
                   TrialTypes(currentTrial) = 2; % type 2 means reward at right 
                else
                   TrialTypes(currentTrial) = 1; % type 1 means reward at left
                end
                
            else
                
                pTarget(currentTrial) = sum(Cloud<9)/sum(Cloud>0);
                
                TargetOctave = 'low';
                
                if strcmp(S.GUI.FreqSide.string(S.GUI.FreqSide.value),'LowLeft')
                   TrialTypes(currentTrial) = 1; % type 1 means reward at left 
                else
                   TrialTypes(currentTrial) = 2; % type 1 means reward at right
                end
                
            end
            
            if TrialTypes(currentTrial)==1 % type 1 means reward at left
                LeftActionState = 'Reward'; RightActionState = 'Punish'; CorrectWithdrawalEvent = 'Port1Out';
                ValveCode = 1; ValveTime = LeftValveTime;
                RewardedPort = {'Port1In'};PunishedPort = {'Port3In'};
            else                           % type 2 means reward at right
                LeftActionState = 'Punish'; RightActionState = 'Reward'; CorrectWithdrawalEvent = 'Port3Out';
                ValveCode = 4; ValveTime = RightValveTime;
                RewardedPort = {'Port3In'}; PunishedPort = {'Port1In'};
            end
            
            
            if pulsepal_connected
                if S.GUI.OptoOn.value
                    if rand<(S.GUI.OptoProb.string)
                    
                        OptoTrial(currentTrial) = 1;
                        
                        OptoSettings{currentTrial}.OptoPulseFreq = S.GUI.OptoPulseFreq.string;
                        OptoSettings{currentTrial}.InterPulseInterval = round((1/S.GUI.OptoPulseFreq.string)*10^4)/10^4;
                        OptoSettings{currentTrial}.OptoPulseWidth = S.GUI.OptoPulseWidth.string/1000;
                        OptoSettings{currentTrial}.OptoDuration = S.GUI.OptoOffset.string-S.GUI.OptoOnset.string;
                        OptoSettings{currentTrial}.OptoOnset = S.GUI.OptoOnset.string;
                        
                        ProgramPulsePalParam(4, 'Phase1Voltage', 1); % Set output channel 1 to produce 2.5V pulses
                        ProgramPulsePalParam(4, 'Phase1Duration', OptoSettings{currentTrial}.OptoPulseWidth); % Set output channel 1 to produce 2ms pulses
                        ProgramPulsePalParam(4, 'InterPulseInterval', OptoSettings{currentTrial}.InterPulseInterval); % Set pulse interval
                        ProgramPulsePalParam(4, 'PulseTrainDuration', OptoSettings{currentTrial}.OptoDuration); % Set pulse train duration
                        ProgramPulsePalParam(4, 'PulseTrainDelay', OptoSettings{currentTrial}.OptoOnset); % Set pulse latency from trigger                      
                    end
                end
            end
            
            sma = NewStateMatrix(); % Assemble state matrix
            
            sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port2In', 'Delay'},...
                'OutputActions',{'PWM2', 255});
            sma = AddState(sma, 'Name', 'Delay', ...
                'Timer', PrestimDuration(currentTrial),...
                'StateChangeConditions', {'Tup', 'DeliverStimulus', 'Port2Out', 'EarlyWithdrawal'},...
                'OutputActions', {'PWM2', 255});

            if OptoTrial(currentTrial)
                
                sma = AddState(sma, 'Name', 'DeliverStimulus', ...
                    'Timer', SoundDuration(currentTrial),...
                    'StateChangeConditions', {'Tup', 'Memory', 'Port2Out', 'EarlyWithdrawal'},...
                    'OutputActions', {'SoftCode', 1, 'BNCState', 1, 'BNCState', 2, 'PWM2', 255});
            else
                
                sma = AddState(sma, 'Name', 'DeliverStimulus', ...
                    'Timer', SoundDuration(currentTrial),...
                    'StateChangeConditions', {'Tup', 'Memory', 'Port2Out', 'EarlyWithdrawal'},...
                    'OutputActions', {'SoftCode', 1, 'BNCState', 1, 'PWM2', 255});
            end
            
            sma = AddState(sma, 'Name', 'Memory', ...
                'Timer', MemoryDuration(currentTrial),...
                'StateChangeConditions', {'Tup', 'GoSignal', 'Port2Out', 'EarlyWithdrawal'},...
                'OutputActions', {'PWM2', 255});

            sma = AddState(sma, 'Name', 'GoSignal', ...
                'Timer', CenterValveTime,...
                'StateChangeConditions', {'Tup', 'WaitForResponse'},...
                'OutputActions', {'ValveState', CenterValveCode,'PWM2', 255});

            sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'EarlyWithdrawalPunish'},...
                'OutputActions', {'SoftCode', 255,'PWM2', 255});
            
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', S.GUI.TimeForResponse.string,...
                'StateChangeConditions', {'Tup', 'exit', RewardedPort, 'Reward', PunishedPort, 'Punish'},...
                'OutputActions', {'PWM1', 255, 'PWM3', 255});
            
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', ValveCode, 'PWM1', 255,'PWM3', 255});
            
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0,...
                'StateChangeConditions', {CorrectWithdrawalEvent, 'exit'},...
                'OutputActions', {'PWM1', 255,'PWM3', 255});
            
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.TimeoutDuration.string,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 3});
            
            sma = AddState(sma, 'Name', 'EarlyWithdrawalPunish', ...
                'Timer', S.GUI.TimeoutDuration.string,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 3});
            
            SendStateMatrix(sma);
            RawEvents = RunStateMatrix;     
    
    end
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.EvidenceStrength(currentTrial) = EvidenceStrength(currentTrial); 
        BpodSystem.Data.pTarget(currentTrial) = pTarget(currentTrial); 
        BpodSystem.Data.PrestimDuration(currentTrial) = PrestimDuration(currentTrial); % 
        BpodSystem.Data.SoundDuration(currentTrial) = SoundDuration(currentTrial); % 
        BpodSystem.Data.MemoryDuration(currentTrial) = MemoryDuration(currentTrial); % 
        BpodSystem.Data.StimulusSettings = StimulusSettings; % Save Stimulus settings
        BpodSystem.Data.Cloud{currentTrial} = Cloud; % Saves Stimulus 
        BpodSystem.Data.StimulusVolume(currentTrial) = StimulusSettings.Volume;
        
        % Side (this works becasue in each trial once the animal goes into one port is either a reward or a punishment and then exit - there are no two ports-in in one trial)
        if isfield(BpodSystem.Data.RawEvents.Trial{currentTrial}.Events,'Port1In') 
            Side(currentTrial) = 1; %Left
        elseif isfield(BpodSystem.Data.RawEvents.Trial{currentTrial}.Events,'Port3In')
            Side(currentTrial) = 2; %Right
        else
            Side(currentTrial) = nan; %Invalid
        end                      
        
        %Outcome
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
            Outcomes(currentTrial) = 1;
            AccumulatedReward = AccumulatedReward+S.GUI.RewardAmount.string;
            controlStep_Prestim = controlStep_Prestim+1; % update because this is a valid trial
            controlStep_Sound = controlStep_Sound+1; % update because this is a valid trial
            controlStep_Memory = controlStep_Memory+1; % update because this is a valid trial
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
            Outcomes(currentTrial) = 0;
            controlStep_Prestim = controlStep_Prestim+1; % update because this is a valid trial
            controlStep_Sound = controlStep_Sound+1; % update because this is a valid trial
            controlStep_Memory = controlStep_Memory+1; % update because this is a valid trial
        else
            Outcomes(currentTrial) = -1;
        end
        
        BpodSystem.Data.Outcomes(currentTrial) = Outcomes(currentTrial);
        BpodSystem.Data.Side(currentTrial) = Side(currentTrial);
        BpodSystem.Data.AccumulatedReward = AccumulatedReward;
        BpodSystem.Data.OptoTrial(currentTrial) = OptoTrial(currentTrial);
        BpodSystem.Data.OptoSettings(currentTrial) = OptoSettings(currentTrial);
        
        
        %Update plots
        UpdateOutcomePlot(TrialTypes, Outcomes);
        UpdatePerformancePlot(TrialTypes, Outcomes,SessionBirthdate);
        UpdatePsychoPlot(TrialTypes, Outcomes);
%         UpdateBinoPlot();
        UpdateStimulusPlot(Cloud_toplot);
        
        
        
        PokesPlot('update');
        
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    if BpodSystem.BeingUsed == 0
        return
    end
end

function UpdateOutcomePlot(TrialTypes, Outcomes)
global BpodSystem
EvidenceStrength = BpodSystem.Data.EvidenceStrength;
nTrials = BpodSystem.Data.nTrials;
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',nTrials+1,2-TrialTypes,Outcomes,EvidenceStrength);

function UpdatePerformancePlot(TrialTypes, Outcomes,SessionBirthdate)
global BpodSystem
nTrials = BpodSystem.Data.nTrials;
PerformancePlot(BpodSystem.GUIHandles.PerformancePlot,'update',nTrials,2-TrialTypes,Outcomes,SessionBirthdate);

function UpdatePsychoPlot(TrialTypes, Outcomes)
global BpodSystem
%EvidenceStrength = BpodSystem.Data.EvidenceStrength;
pTarget = BpodSystem.Data.pTarget;
nTrials = BpodSystem.Data.nTrials;
PsychoPlot(BpodSystem.GUIHandles.PsychoPlot,'update',nTrials,2-TrialTypes,Outcomes,pTarget);


% function UpdateBinoPlot()
% global BpodSystem
% 
% %pTarget = (1/2+r/2);
% %EvidenceStrength = 2*(pTarget-1/2);
% Predictor = {(2*BpodSystem.Data.pTarget-1).*(2*BpodSystem.Data.TrialTypes-3);...
%              (BpodSystem.Data.StimulusVolume-55)/10};
% Response = BpodSystem.Data.Side;
% Valid = BpodSystem.Data.Outcomes>=0;
% BinoPlot(BpodSystem.GUIHandles.PsychoPlot,'update',Predictor,Response,Valid);        
        

function UpdateStimulusPlot(Cloud)
global BpodSystem
%CloudDetails.EvidenceStrength = BpodSystem.Data.EvidenceStrength(end);
CloudDetails.pTarget = BpodSystem.Data.pTarget(end);
if sum(BpodSystem.Data.Cloud{end}>9)>sum(BpodSystem.Data.Cloud{end}<9)
    CloudDetails.Target = 'High';
else
    CloudDetails.Target = 'Low';    
end

StimulusPlot(BpodSystem.GUIHandles.StimulusPlot,'update',Cloud,CloudDetails);