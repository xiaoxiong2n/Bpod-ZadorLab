
function ToneCloudsReactionTime

% This protocol implements ToneClouds (developed by P. Znamenskiy) on Bpod
% Based on PsychoToolboxSound (written by J.Sanders)

% Written by F.Carnevale, 2/2015.

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

    S.GUI.Subject.panel = 'Protocol'; S.GUI.Subject.style = 'text'; S.GUI.Subject.string = BpodSystem.GUIData.SubjectName;    
    S.GUI.Stage.panel = 'Protocol'; S.GUI.Stage.style = 'popupmenu'; S.GUI.Stage.string = {'Direct', 'Full task'}; S.GUI.Stage.value = 1;% Training stage
    
    % Stimulus section
    S.GUI.UseMiddleOctave.panel = 'Stimulus settings'; S.GUI.UseMiddleOctave.style = 'popupmenu'; S.GUI.UseMiddleOctave.string = {'no', 'yes'}; S.GUI.UseMiddleOctave.value = 1;% Training stage
    S.GUI.VolumeMin.panel = 'Stimulus settings'; S.GUI.VolumeMin.style = 'edit'; S.GUI.VolumeMin.string = 50; % Lowest volume dB
    S.GUI.VolumeMax.panel = 'Stimulus settings'; S.GUI.VolumeMax.style = 'edit'; S.GUI.VolumeMax.string = 70; % Highest Volume dB
    S.GUI.DifficultyLow.panel = 'Stimulus settings'; S.GUI.DifficultyLow.style = 'edit'; S.GUI.DifficultyLow.string = 1; % Lowest difficulty
    S.GUI.DifficultyHigh.panel = 'Stimulus settings'; S.GUI.DifficultyHigh.style = 'edit'; S.GUI.DifficultyHigh.string = 1; % Highest difficulty
    S.GUI.nDifficulties.panel = 'Stimulus settings'; S.GUI.nDifficulties.style = 'edit'; S.GUI.nDifficulties.string = 0; % Highest difficulty
    S.GUI.ToneOverlap.panel = 'Stimulus settings'; S.GUI.ToneOverlap.style = 'edit'; S.GUI.ToneOverlap.string = 0; % Overlap between tones (0 to 1) 0 meaning no overlap
    S.GUI.ToneDuration.panel = 'Stimulus settings'; S.GUI.ToneDuration.style = 'edit'; S.GUI.ToneDuration.string = 0.03;
    S.GUI.NoEvidence.panel = 'Stimulus settings'; S.GUI.NoEvidence.style = 'edit'; S.GUI.NoEvidence.string = 0; % Number of tones with no evidence
    S.GUI.AudibleHuman.panel = 'Stimulus settings'; S.GUI.AudibleHuman.style = 'checkbox'; S.GUI.AudibleHuman.string = 'AudibleHuman'; S.GUI.AudibleHuman.value = 1;
    
    % Reward 
    S.GUI.RewardAmount.panel = 'Reward settings'; S.GUI.RewardAmount.style = 'edit'; S.GUI.RewardAmount.string = 2.5;
    S.GUI.FreqSide.panel = 'Reward settings'; S.GUI.FreqSide.style = 'popupmenu'; S.GUI.FreqSide.string = {'LowLeft', 'LowRight'}; S.GUI.FreqSide.value = 1;% Training stage
    S.GUI.PunishSound.panel = 'Reward settings'; S.GUI.PunishSound.style = 'checkbox'; S.GUI.PunishSound.string = 'Active';  S.GUI.PunishSound.value = 2;
        
    % Trial structure section     
    S.GUI.TimeForResponse.panel = 'Trial Structure'; S.GUI.TimeForResponse.style = 'edit'; S.GUI.TimeForResponse.string = 10;
    S.GUI.TimeoutDuration.panel = 'Trial Structure'; S.GUI.TimeoutDuration.style = 'edit'; S.GUI.TimeoutDuration.string = 4;    
    
    S.GUI.PrestimDistribution.panel = 'Prestim Timing'; S.GUI.PrestimDistribution.style = 'popupmenu'; S.GUI.PrestimDistribution.string = {'Delta', 'Uniform', 'Exponential'}; S.GUI.PrestimDistribution.value = 1;% Training stage
    S.GUI.PrestimDurationStart.panel = 'Prestim Timing'; S.GUI.PrestimDurationStart.style = 'edit'; S.GUI.PrestimDurationStart.string = 0.050; % Prestim duration start
    S.GUI.PrestimDurationEnd.panel = 'Prestim Timing'; S.GUI.PrestimDurationEnd.style = 'edit'; S.GUI.PrestimDurationEnd.string = 0.050; % Prestim duration end
    S.GUI.PrestimDurationStep.panel = 'Prestim Timing'; S.GUI.PrestimDurationStep.style = 'edit'; S.GUI.PrestimDurationStep.string = 0.050; % Prestim duration end
    S.GUI.PrestimDurationNtrials.panel = 'Prestim Timing'; S.GUI.PrestimDurationNtrials.style = 'edit'; S.GUI.PrestimDurationNtrials.string = 50; %
    S.GUI.PrestimDurationCurrent.panel = 'Prestim Timing'; S.GUI.PrestimDurationCurrent.style = 'text'; S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationStart.string; % Prestim duration end    
    
    S.GUI.SoundMaxDuration.panel = 'Stimulus Timing'; S.GUI.SoundMaxDuration.style = 'edit'; S.GUI.SoundMaxDuration.string = 1; % Sound duration start
    
    % Antibias
    S.GUI.Antibias.panel = 'Antibias'; S.GUI.Antibias.style = 'popupmenu'; S.GUI.Antibias.string = {'no', 'yes'}; S.GUI.Antibias.value = 1;% Training stage
    
    if S.GUI.AudibleHuman.value, minFreq = 200; maxFreq = 2000; else minFreq = 5000; maxFreq = 40000; end

    % Other Stimulus settings (not in the GUI)
    StimulusSettings.ToneOverlap = S.GUI.ToneOverlap.string;
    StimulusSettings.ToneDuration = S.GUI.ToneDuration.string;
    StimulusSettings.minFreq = minFreq;
    StimulusSettings.maxFreq = maxFreq;
    StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
    StimulusSettings.UseMiddleOctave = S.GUI.UseMiddleOctave.string(S.GUI.UseMiddleOctave.value);
    StimulusSettings.Noevidence = S.GUI.NoEvidence.string;   
    StimulusSettings.nFreq = 18; % Number of different frequencies to sample from
    StimulusSettings.ramp = 0.005;    
    
end

%% Define trials
MaxTrials = 5000;
TrialTypes = ceil(rand(1,MaxTrials)*2); % correct side for each trial
EvidenceStrength = nan(1,MaxTrials); % evidence strength for each trial
PrestimDuration = nan(1,MaxTrials); % prestimulation delay period for each trial
Outcomes = nan(1,MaxTrials);
AccumulatedReward=0;

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.EvidenceStrength = []; % The evidence strength of each trial completed will be added here.
BpodSystem.Data.PrestimDuration = []; % The evidence strength of each trial completed will be added here.

%% Initialize plots

% Initialize parameter GUI plugin
EnhancedBpodParameterGUI('init', S);


% Outcome plot
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [457 803 1000 163],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
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

% Stimulus plot
BpodSystem.ProtocolFigures.StimulusPlotFig = figure('Position', [457 803 500 300],'name','Stimulus plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.StimulusPlot = axes('Position', [.15 .2 .75 .65]);
StimulusPlot(BpodSystem.GUIHandles.StimulusPlot,'init',StimulusSettings.nFreq);

%%% Pokes plot
state_colors = struct( ...
        'WaitForCenterPoke', [0.5 0.5 1],...
        'Delay',0.3*[1 1 1],...
        'DeliverStimulus', 0.75*[1 1 0],...
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
BpodSystem.GUIHandles.MainFig.Position = [423 395 BpodSystem.GUIHandles.MainFig.Position(3:4)];
BpodSystem.ProtocolFigures.Notebook.Position = [175 15 BpodSystem.ProtocolFigures.Notebook.Position(3:4)];
BpodSystem.ProtocolFigures.BpodParameterGUI.Position = [66 330 BpodSystem.ProtocolFigures.BpodParameterGUI.Position(3:4)];
BpodSystem.ProtocolFigures.PerformancePlotFig.Position = [418 795 BpodSystem.ProtocolFigures.PerformancePlotFig.Position(3:4)];
BpodSystem.ProtocolFigures.OutcomePlotFig.Position = [418 986 BpodSystem.ProtocolFigures.OutcomePlotFig.Position(3:4)];
BpodSystem.ProtocolFigures.PsychoPlotFig.Position = [821 33 BpodSystem.ProtocolFigures.PsychoPlotFig.Position(3:4)];


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
PsychToolboxSoundServer('Load', 2, 0);
PsychToolboxSoundServer('Load', 3, PunishSound);
PsychToolboxSoundServer('Load', 4, EarlyWithdrawalSound);

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'ToneCloud Protocol...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

% Disable changing task 
BpodSystem.GUIHandles.ParameterGUI.ParamValues(strcmp(BpodSystem.GUIHandles.ParameterGUI.ParamNames,'Stage')==1).Enable = 'off';

% Set timer for this session
SessionBirthdate = tic;

% Control the step up of prestimulus period and stimulus duration
controlStep_Prestim = 0; % valid trial counter

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
        if controlStep_Prestim > controlStep_nRequiredValid_Prestim

            controlStep_Prestim = 0; %restart counter

            % step up, unless we are at the max
            if S.GUI.PrestimDurationCurrent.string + S.GUI.PrestimDurationStep.string > S.GUI.PrestimDurationEnd.string
                S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationEnd.string;
            else
                S.GUI.PrestimDurationCurrent.string = S.GUI.PrestimDurationCurrent.string + S.GUI.PrestimDurationStep.string;
            end
        end
    else
       S.GUI.PrestimDurationCurrent.string =  S.GUI.PrestimDurationStart.string;
    end    
    
    
    switch S.GUI.PrestimDistribution.value
        case 1
            PrestimDuration(currentTrial) = S.GUI.PrestimDurationCurrent.string;
        case 2'
            PrestimDuration(currentTrial) = rand+S.GUI.PrestimDurationCurrent.string-0.5;
        case 3
            PrestimDuration(currentTrial) = exprnd(S.GUI.PrestimDurationCurrent.string);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    R = GetValveTimes(S.GUI.RewardAmount.string, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    
    % Update stimulus settings
    StimulusSettings.nTones = floor((S.GUI.SoundMaxDuration.string-S.GUI.ToneDuration.string*S.GUI.ToneOverlap.string)/(S.GUI.ToneDuration.string*(1-S.GUI.ToneOverlap.string)));
    StimulusSettings.ToneOverlap = S.GUI.ToneOverlap.string;
    StimulusSettings.ToneDuration = S.GUI.ToneDuration.string;
    StimulusSettings.minFreq = minFreq;
    StimulusSettings.maxFreq = maxFreq;
    StimulusSettings.UseMiddleOctave = S.GUI.UseMiddleOctave.string(S.GUI.UseMiddleOctave.value);
    StimulusSettings.Noevidence = S.GUI.NoEvidence.string;  
    StimulusSettings.VolumeMin = S.GUI.VolumeMin.string;
    StimulusSettings.VolumeMax = S.GUI.VolumeMax.string;
    
    StimulusSettings.Volume = (randi(10)-1)/4*(StimulusSettings.VolumeMax-StimulusSettings.VolumeMin) + StimulusSettings.VolumeMin
    
    if S.GUI.Antibias.value==2 %apply antibias
        if Outcomes(currentTrial-1)==0
            TrialTypes(currentTrial)=TrialTypes(currentTrial-1);
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
    
    switch S.GUI.Stage.value
        
        case 1 % Training stage 1: Direct sides - Poke and collect water
            
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
                'StateChangeConditions', {'Tup', 'DeliverStimulus', 'Port2Out', 'EarlyWithdrawal'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DeliverStimulus', ...
                'Timer', S.GUI.SoundMaxDuration.string,...
                'StateChangeConditions', {'Tup', 'Reward'},...
                'OutputActions', {'SoftCode', 1, 'BNCState', 1});
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
            
        case 2 % Full task

            DifficultySet = [S.GUI.DifficultyLow.string S.GUI.DifficultyLow.string:(S.GUI.DifficultyHigh.string-S.GUI.DifficultyLow.string)/(S.GUI.nDifficulties.string-1):S.GUI.DifficultyHigh.string S.GUI.DifficultyHigh.string];
            DifficultySet = unique(DifficultySet);

            EvidenceStrength(currentTrial) = DifficultySet(randi(size(DifficultySet,2)));

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
                'StateChangeConditions', {'Tup', 'DeliverStimulus', 'Port2Out', 'EarlyWithdrawal'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'DeliverStimulus', ...
                'Timer', S.GUI.SoundMaxDuration.string,...
                'StateChangeConditions', {'Port2Out', 'WaitForResponse'},...
                'OutputActions', {'SoftCode', 1, 'BNCState', 1});
            sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'EarlyWithdrawalPunish'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', S.GUI.TimeForResponse.string,...
                'StateChangeConditions', {'Tup', 'exit', 'Port1In', LeftActionState, 'Port3In', RightActionState},...
                'OutputActions', {'SoftCode', 255, 'BNCState', 0});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', ValveCode});
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0,...
                'StateChangeConditions', {CorrectWithdrawalEvent, 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Punish', ...
                'Timer', S.GUI.TimeoutDuration.string,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 4});
            sma = AddState(sma, 'Name', 'EarlyWithdrawalPunish', ...
                'Timer', S.GUI.TimeoutDuration.string,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {'SoftCode', 4});
            
            SendStateMatrix(sma);
            RawEvents = RunStateMatrix;
    end
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.EvidenceStrength(currentTrial) = EvidenceStrength(currentTrial); % Adds the evidence strength of the current trial to data
        BpodSystem.Data.PrestimDuration(currentTrial) = PrestimDuration(currentTrial); % Adds the evidence strength of the current trial to data
        
        %%
        %BpodSystem.Data.SoundDuration(currentTrial) = SoundDuration(currentTrial); % Adds the evidence strength of the current trial to data
        %%
        
        BpodSystem.Data.StimulusSettings = StimulusSettings; % Save Stimulus settings
        BpodSystem.Data.Cloud{currentTrial} = Cloud; % Saves Stimulus 
        
        %Outcome
        if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
            Outcomes(currentTrial) = 1;
            AccumulatedReward = AccumulatedReward+S.GUI.RewardAmount.string;
            controlStep_Prestim = controlStep_Prestim+1; % update because this is a valid trial
            %controlStep_Sound = controlStep_Sound+1; % update because this is a valid trial
        elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Punish(1))
            Outcomes(currentTrial) = 0;
            controlStep_Prestim = controlStep_Prestim+1; % update because this is a valid trial
            %controlStep_Sound = controlStep_Sound+1; % update because this is a valid trial
        else
            Outcomes(currentTrial) = -1;
        end
        
        BpodSystem.Data.Outcomes(currentTrial) = Outcomes(currentTrial);
        BpodSystem.Data.AccumulatedReward = AccumulatedReward;
        
        
        UpdateOutcomePlot(TrialTypes, Outcomes);
        UpdatePerformancePlot(TrialTypes, Outcomes,SessionBirthdate);
        UpdatePsychoPlot(TrialTypes, Outcomes);
        
        tDeliverStimulus = diff(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.DeliverStimulus);
        UpdateStimulusPlot(Cloud_toplot,tDeliverStimulus);
        
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
EvidenceStrength = BpodSystem.Data.EvidenceStrength;
nTrials = BpodSystem.Data.nTrials;
PsychoPlot(BpodSystem.GUIHandles.PsychoPlot,'update',nTrials,2-TrialTypes,Outcomes,EvidenceStrength);

function UpdateStimulusPlot(Cloud,tDeliverStimulus)
global BpodSystem
CloudDetails.EvidenceStrength = BpodSystem.Data.EvidenceStrength(end);
StimulusPlot(BpodSystem.GUIHandles.StimulusPlot,'update',Cloud,CloudDetails,tDeliverStimulus);