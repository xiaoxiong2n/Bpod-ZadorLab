
% My first protocol for Bpod
% David Raposo, Sep 2014
% Based on RateDiscrimination (by Kachi)

% Modification history
% 26-Sep-2014 by KO: Separate rewards for each port
%                    Event rate list
% 10-Oct-2014 by KO: Added Matt Kaufman's antibias code
% 30-Oct-2014 by KO: Changed category boundary to 12 events/s, such that 12
%                    evts/s is randomly rewarded. Changed ">" or "<" before categoryBoundary
%                    to ">=" or "<=" categoryBoundary
% 04-Jan-2015 by KO: Incorporated Matt Kaufman's antibias function
%                    Added option for center port reward

function TheSlipperyFish

global BpodSystem

% Initialize sound server
PsychToolboxSoundServer('init')
% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

%% Define settings for protocol

%Initialize default settings. 
%Append new settings to the end
DefaultSettings.SubjectName = 'Fish';
DefaultSettings.leftRewardVolume = 4; % ul
DefaultSettings.rightRewardVolume = 4;% ul
DefaultSettings.centerRewardVolume = 0;% ul
DefaultSettings.highRateSide = 'R';
DefaultSettings.preStimDelayMin = 0.01; % secs
DefaultSettings.preStimDelayMax = 0.1; % secs
DefaultSettings.lambdaDelay = 15;
DefaultSettings.minWaitTime = 0.5; % secs
DefaultSettings.minWaitTimeStep = 0.0003;% secs
DefaultSettings.timeToChoose = 3; % secs
DefaultSettings.timeOut = 2; % secs
DefaultSettings.visEventRateList = [4 6 8 16 18 20]; %events per second
DefaultSettings.audEventRateList = [4 6 8 16 18 20]; %events per second
DefaultSettings.multEventRateList = [4 6 8 16 18 20]; %events per second
DefaultSettings.PropLeft = 0.5;
DefaultSettings.PropOnlyAuditory = 0;
DefaultSettings.PropOnlyVisual = 1;
DefaultSettings.SynchMultiSensory = 1;
DefaultSettings.WaitStartCue = 0;
DefaultSettings.WaitEndGoCue = 1;
DefaultSettings.PlayStimulus = 1;
DefaultSettings.StimBrightness = 20;
DefaultSettings.StimLoudness = 1;
DefaultSettings.Direct = 0; %this will reflect the probability/fraction of trials that are direct reward
DefaultSettings.UseAntiBias = 0;
DefaultSettings.AntiBiasTau = 4;
DefaultSettings.CategoryBoundary = 12; %events/s

defaultFieldParamVals = struct2cell(DefaultSettings);
defaultFieldNames = fieldnames(DefaultSettings);

S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct S
currentFieldNames = fieldnames(S);

if isempty(fieldnames(S)) % If settings file was an empty struct, populate struct with default settings
    S = DefaultSettings;
    
elseif numel(defaultFieldNames) > numel(currentFieldNames)  %an addition to default settings, update 
    differentI = find(~ismember(defaultFieldNames,currentFieldNames)); %find the index
    for ii = 1:numel(differentI)
        thisnewfield = defaultFieldNames{differentI(ii)};
        S.(thisnewfield)=defaultFieldParamVals{differentI(ii)};
    end
end

% Launch parameter GUI
BpodParameterGUI_Visual('init', S);

%%
SamplingFreq = 192000; % This has to match the sampling rate initialized in PsychToolboxSoundServer.m

% Preconfigure audio signals and load to psychtoolbox
generateAndUploadSounds(SamplingFreq, S.StimLoudness);

PrevStimLoudness = S.StimLoudness;

% ports are numbered 0-7. Need to convert to 8bit values for bpod
LeftPort = 2^0;
CenterPort = 2^1;
RightPort = 2^2;

% Stimulus parameters
% The parameters below are typically not changed from trial to trial, so
% keep fixed for now. Nonetheless, save on each trial

eventDuration = 0.020; % secs
categoryBoundary = S.CategoryBoundary; % events/sec
desiredStimDuration =  1; % secs

% Create trial types (left vs right)
maxTrials = 5000;
coin = rand(1,maxTrials);
TrialSidesList = coin > (1-S.PropLeft);
TrialSidesList = TrialSidesList(randperm(maxTrials));
PrevPropLeft = S.PropLeft;

% Antibias parameters
AntiBiasPrevLR =  NaN;
AntiBiasPrevSuccess = NaN;
SuccessArray = 0.5 * ones(2, 2, 2);    % successArray will be: prevTrialLR x prevTrialSuccessful x thisTrialLR
ModalityRightArray = 0.5 * ones(1, 3);

%% Initialize plots
BpodSystem.GUIHandles.Figures.FigureAllFigures = figure('Position', [500 1000 600 700], 'name', 'All Plots', 'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Units', 'pixels', 'Position', [70 580 500 100]);
BpodSystem.GUIHandles.PerformancePlot = axes('Units', 'pixels', 'Position', [70 440 500 100]);
BpodSystem.GUIHandles.StimulusPlot = axes('Units', 'pixels', 'Position', [70 360 500 40]);
BpodSystem.GUIHandles.PMFPlot = axes('Units', 'pixels', 'Position', [70 30 240 280]);

OutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', TrialSidesList, 60);
PerformancePlot(BpodSystem.GUIHandles.PerformancePlot,'init');

%% Initialize arrays for storing values later
OutcomeRecord = nan(1,maxTrials);
Rewarded = nan(1,maxTrials);
EarlyWithdrawal = nan(1,maxTrials);
DidNotChoose = nan(1,maxTrials);
ResponseSideRecord = nan(1,maxTrials);
modalityRecord = nan(1,maxTrials);
correctSideRecord = nan(1,maxTrials);

TrialsDone =  0;

%% Main loop
for currentTrial = 1:maxTrials
    
    S = BpodParameterGUI_Visual('update', S); drawnow; % Sync parameters with BpodParameterGUI plugin
    
    % If the stimulus loudness was changed, then regenerate and
    % re-upload the sounds to the sound server
    if PrevStimLoudness ~= S.StimLoudness
        generateAndUploadSounds(SamplingFreq, S.StimLoudness);
        PrevStimLoudness = S.StimLoudness;
    end
    
    LeftValveTime = GetValveTimes(S.leftRewardVolume, 1);
    RightValveTime = GetValveTimes(S.rightRewardVolume, 3);
    CenterValveTime = 0;

    if S.centerRewardVolume > 0
        CenterValveTime = GetValveTimes(S.centerRewardVolume, 2);
    end 
    
    directTrial = rand < S.Direct; %probability of direct reward
    
    if TrialsDone > 1
        outcome  = OutcomeRecord(TrialsDone);
        if outcome > -1
            
            % Update arrays
            [newModalityRightArray, newSuccessArray] = updateAntiBiasArrays(ModalityRightArray, SuccessArray, ...
                                                   modalityRecord(TrialsDone - 1), outcome, ...
                                                   correctSideRecord(TrialsDone -1), ...
                                                   AntiBiasPrevLR, AntiBiasPrevSuccess, ...
                                                   S.AntiBiasTau, ResponseSideRecord(TrialsDone - 1) - 1);
            
            % Update history
            AntiBiasPrevLR = correctSideRecord(TrialsDone -1);
            AntiBiasPrevSuccess = (OutcomeRecord(TrialsDone -1) == 1);
            
            % Update matrices
            SuccessArray= newSuccessArray;
            ModalityRightArray= newModalityRightArray;
            
        end
        
    end %end TrialsDone%
    
    preStimDelay = generate_random_delay(S.lambdaDelay, S.preStimDelayMin, S.preStimDelayMax);
    %         postStimDelay = generate_random_delay(S.lambdaDelay, S.postStimDelayMin, S.postStimDelayMax);
    
    % Determine stimulus modality
    show_audio = 0;
    show_visual = 0;
    coin = rand;
    
    if coin < S.PropOnlyAuditory % only audio
        Modality = 'Auditory';
        disp('Auditory trial');
        show_audio = 1;
        modalityNum = 1;
        
    elseif coin < S.PropOnlyVisual + S.PropOnlyAuditory % only visual
        Modality = 'Visual';
        disp('Visual trial');
        show_visual = 1;
        modalityNum = 2;
        
    else % audio & visual
        Modality = 'Multisensory';
        disp('Multisensory trial');
        show_audio = 1;
        show_visual = 1;
        modalityNum= 3;
        
    end
    
    % Anti-bias for coming trial
    % If we've previously done a trial, are using anti-bias, and the
    % previous trial wasn't an early withdrawal or failure to choose,
    % update the next trial.
    % Note: at this point in the trial, 'outcome' is still from the
    % previous trial
    
    % First ensure that anti-bias strength is a sane value, between 0 and 1
    if S.UseAntiBias < 0
        S.UseAntiBias = 0;
    elseif S.UseAntiBias > 1
        S.UseAntiBias = 1;
    end
    
    if TrialsDone > 1 && S.UseAntiBias > 0 && outcome > -1
        
        pLeft = getAntiBiasPLeft(SuccessArray, ModalityRightArray, modalityNum, ...
            S.UseAntiBias, AntiBiasPrevLR, AntiBiasPrevSuccess);
        
        coin = rand(1);
        sidesList = TrialSidesList;
     
        sidesList(currentTrial) = coin > (1 - pLeft); %the sign is important, it must match the way left and right trials are assigned based on prop left/right
        TrialSidesList = sidesList;
        
    elseif TrialsDone > 1 && (S.PropLeft ~= PrevPropLeft) && (S.UseAntiBias == 0)
        % If experimenter changed PropLeft, then we need to recompute the
        % side of the future trials
        ntrialsRemaining = numel(TrialSidesList(currentTrial:end));
        coin = rand(1,ntrialsRemaining);
        FutureTrials = coin > (1-S.PropLeft);
        FutureTrials  = FutureTrials(randperm(ntrialsRemaining));
        TrialSidesList(currentTrial:end) = FutureTrials;
        PrevPropLeft = S.PropLeft;
        
    end %end S.UseAntiBias, S.PropLeft
    
    if TrialsDone > 0
        UpdateOutcomePlot(TrialSidesList, BpodSystem.Data);
    end
    
    % Pick this trial type
    thisTrialSide = TrialSidesList(currentTrial);
    
    if thisTrialSide == 1 % Leftward trial
        LeftPortAction = 'Reward';
        RightPortAction = 'SoftPunish';
        RewardValve = LeftPort; %left-hand port represents port#0, therefore valve value is 2^0
        rewardValveTime = LeftValveTime;
        correctSide = 1;
        
        if strcmpi(S.highRateSide ,'R')
            audEventList = S.audEventRateList(S.audEventRateList <= categoryBoundary);
            visEventList = S.visEventRateList(S.visEventRateList <= categoryBoundary);
            multEventList = S.multEventRateList(S.multEventRateList <= categoryBoundary);
        else
            audEventList = S.audEventRateList(S.audEventRateList >= categoryBoundary);
            visEventList = S.visEventRateList(S.visEventRateList >= categoryBoundary);
            multEventList = S.multEventRateList(S.multEventRateList >= categoryBoundary);
        end
    else % Rightward trial (thisTrialSide == 0)
        LeftPortAction = 'SoftPunish';
        RightPortAction = 'Reward';
        RewardValve = RightPort; %right-hand port represents port#2, therefore valve value is 2^2
        rewardValveTime = RightValveTime;
        correctSide = 2;
        
        if strcmpi(S.highRateSide ,'R')
            audEventList = S.audEventRateList(S.audEventRateList >= categoryBoundary);
            visEventList = S.visEventRateList(S.visEventRateList >= categoryBoundary);
            multEventList = S.multEventRateList(S.multEventRateList >= categoryBoundary);
        else
            audEventList = S.audEventRateList(S.audEventRateList <= categoryBoundary);
            visEventList = S.visEventRateList(S.visEventRateList <= categoryBoundary);
            multEventList = S.multEventRateList(S.multEventRateList <= categoryBoundary);
        end
    end
    
    %Choose modality-specific event rate for this trial
    if coin < S.PropOnlyAuditory % only audio
        
        % randomly shuffle eligible events and pick one
        index = randperm(length(audEventList));
        thisTrialRate = audEventList(index(1));
        
    elseif coin < S.PropOnlyVisual + S.PropOnlyAuditory % only visual
        
        % randomly shuffle eligible events and pick one
        index = randperm(length(visEventList));
        thisTrialRate = visEventList(index(1));
        
    else % audio & visual
        
        % randomly shuffle eligible events and pick one
        index = randperm(length(multEventList));
        thisTrialRate = multEventList(index(1));
    end
    
    % Get the list of random events given the rate for this trial
    [stimEventList,stimflag] = getRandomStimEvents(thisTrialRate, desiredStimDuration, eventDuration);
    
    Signal = [];
    if show_audio == 1
        % Build the actual wave form of the stimulus
        audio_waveform = buildAudioWaveForm(stimEventList, eventDuration, SamplingFreq);
        Signal(2,:) = audio_waveform;
        Signal(1,:) = zeros(size(audio_waveform));
        waveform = audio_waveform;
    end
    
    if show_audio == 1 && show_visual == 1 % multisensory
        if ~S.SynchMultiSensory
            [new_stimEventList,stimflag] = getRandomStimEvents(thisTrialRate, desiredStimDuration, eventDuration);
            visual_waveform = buildVisualWaveForm(new_stimEventList, eventDuration, SamplingFreq, S.StimBrightness);
        else
            visual_waveform = buildVisualWaveForm(stimEventList, eventDuration, SamplingFreq, S.StimBrightness);
        end
        
        if length(visual_waveform) < length(audio_waveform)
            visual_waveform = [visual_waveform zeros(1,length(audio_waveform)-length(visual_waveform))];
        elseif length(audio_waveform) < length(visual_waveform)
            audio_waveform = [audio_waveform zeros(1,length(visual_waveform)-length(audio_waveform))];
        end
        Signal = [visual_waveform; audio_waveform];
        waveform = audio_waveform;
        
    elseif show_audio == 0 && show_visual == 1  % visual-only
        visual_waveform = buildVisualWaveForm(stimEventList, eventDuration, SamplingFreq, S.StimBrightness);
        Signal(1,:) = visual_waveform;
        Signal(2,:) = zeros(size(visual_waveform));
        waveform = visual_waveform;
    end
    
    disp(['This event rate: ' num2str(thisTrialRate) ' events/s'])
    
    plot(BpodSystem.GUIHandles.StimulusPlot, linspace(0,1,length(waveform)), waveform);
    set(BpodSystem.GUIHandles.StimulusPlot, 'box', 'off');
    
    if ~S.PlayStimulus
        Signal = 0;
        Modality = '-';
    end
    
    PsychToolboxSoundServer('Load', 1, Signal); % send signal to sound server
    
    % Determine whether to play start cue or cue
    if ~S.WaitStartCue
        StartCueOutputAction  = {};
    else
        StartCueOutputAction = {'SoftCode', 2};
    end
    
    if ~S.WaitEndGoCue
        GoCueOutputAction  = {};
    else
        GoCueOutputAction = {'SoftCode', 3};
    end
    
    
    % Build state matrix
    
    sma = NewStateMatrix();
    
    sma = AddState(sma, 'Name', 'GoToCenter', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'PlayWaitStartCue'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'PlayWaitStartCue', ...
        'Timer', preStimDelay, ...
        'StateChangeConditions', {'Tup','PlayStimulus', 'Port2Out', 'EarlyWithdrawal'},...
        'OutputActions', StartCueOutputAction);
    
    sma = AddState(sma, 'Name', 'PlayStimulus', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup','WaitCenter', 'Port2Out', 'EarlyWithdrawal'},...
        'OutputActions', {'SoftCode', 1});
    
    sma = AddState(sma, 'Name', 'WaitCenter', ...
        'Timer', S.minWaitTime, ...
        'StateChangeConditions', {'Port2Out', 'EarlyWithdrawal', 'Tup', 'PlayGoTone'}, ...
        'OutputActions',{});
    
    sma = AddState(sma, 'Name', 'PlayGoTone', ...
        'Timer', CenterValveTime, ...
        'StateChangeConditions', {'Tup', 'WaitForWithdrawalFromCenter'},...
        'OutputActions', [GoCueOutputAction,'ValveState', CenterPort]);
    
    sma = AddState(sma, 'Name', 'WaitForWithdrawalFromCenter', ...
        'Timer', S.timeToChoose,...
        'StateChangeConditions', {'Port2Out', 'StopStimulus', 'Tup', 'DidNotChoose'},... % direct reward, change later!!
        'OutputActions', {});
    
    if directTrial == 1
        sma = AddState(sma, 'Name', 'StopStimulus', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'Reward'},...
            'OutputActions', {'SoftCode', 255});
    else
        sma = AddState(sma, 'Name', 'StopStimulus', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', 'WaitForResponse'},...
            'OutputActions', {'SoftCode', 255});
    end
    
    sma = AddState(sma, 'Name', 'WaitForResponse', ...
        'Timer', S.timeToChoose,...
        'StateChangeConditions', {'Port1In', LeftPortAction, 'Port3In', RightPortAction, 'Tup', 'DidNotChoose'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Reward', ...
        'Timer', rewardValveTime,...
        'StateChangeConditions', {'Tup','PrepareNextTrial'},...
        'OutputActions', {'ValveState', RewardValve});
    
    % For soft punishment just give time out
    sma = AddState(sma, 'Name', 'SoftPunish', ...
        'Timer', S.timeOut,...
        'StateChangeConditions', {'Tup','PrepareNextTrial'},...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'EarlyWithdrawal', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'HardPunish'},...
        'OutputActions', {'SoftCode', 255});
    
    % For hard punishment play noise and give time out
    sma = AddState(sma, 'Name', 'HardPunish', ...
        'Timer', S.timeOut, ...
        'StateChangeConditions', {'Tup', 'PrepareNextTrial'}, ...
        'OutputActions', {'SoftCode', 4});
    
    sma = AddState(sma, 'Name', 'DidNotChoose', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'SoftPunish'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'PrepareNextTrial', ...
        'Timer', 0, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {} );
    
    
    % Send and run state matrix
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    % Save events and data
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        
        
        TrialsDone = TrialsDone + 1; %increment number of trials done
        
        % need to save these next five variables as they are no longer
        % included in the settings file.
        BpodSystem.Data.Modality{TrialsDone} = Modality;
        BpodSystem.Data.EventDuration(TrialsDone) = eventDuration;
        BpodSystem.Data.CategoryBoundary(TrialsDone) = categoryBoundary;
        BpodSystem.Data.DesiredStimDuration(TrialsDone) = desiredStimDuration;
        
        Rewarded(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Reward(1));
        EarlyWithdrawal(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.EarlyWithdrawal(1));
        DidNotChoose(TrialsDone) = ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.DidNotChoose(1));
        
        BpodSystem.Data.stimEventList{TrialsDone} = stimEventList;
        BpodSystem.Data.Rewarded(TrialsDone) = Rewarded(TrialsDone);
        BpodSystem.Data.EarlyWithdrawal(TrialsDone) = EarlyWithdrawal(TrialsDone);
        BpodSystem.Data.DidNotChoose(TrialsDone) = DidNotChoose(TrialsDone);
        BpodSystem.Data.EventRate(TrialsDone) = thisTrialRate;
        BpodSystem.Data.PreStimDelay(TrialsDone) = preStimDelay;
        BpodSystem.Data.SetWaitTime(TrialsDone) = S.minWaitTime;
        BpodSystem.Data.DirectReward(TrialsDone) = directTrial;
        BpodSystem.Data.DesiredStimGenerated = stimflag;
        %compute time spent in center for all each trial with one nose poke in
        %and out of the center port. better to compute this now            
        BpodSystem.Data.ActualWaitTime(TrialsDone) = nan;
        if isfield(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events,'Port2Out') && isfield(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events,'Port2In')
            if (numel(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2Out)== 1) && (numel(BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2In) == 1)
                BpodSystem.Data.ActualWaitTime(TrialsDone) = BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2Out - BpodSystem.Data.RawEvents.Trial{1,TrialsDone}.Events.Port2In;
            end
        end
        
        modalityRecord(TrialsDone) = modalityNum;
        correctSideRecord(TrialsDone) = correctSide;
        BpodSystem.Data.CorrectSide(TrialsDone) = correctSideRecord(TrialsDone);
        
        if BpodSystem.Data.Rewarded(TrialsDone) == 1
            %correct!
            OutcomeRecord(TrialsDone) = 1;
        elseif BpodSystem.Data.EarlyWithdrawal(TrialsDone) == 1
            %early withdrawal
            OutcomeRecord(TrialsDone) = -1;
        elseif BpodSystem.Data.DidNotChoose(TrialsDone) == 1
            %did not choose
            OutcomeRecord(TrialsDone) = -2;
        else
            %incorrect
            OutcomeRecord(TrialsDone) = 0;
        end
     
        if OutcomeRecord(TrialsDone) >= 0 %if the subject responded
        
            if ((correctSideRecord(TrialsDone)==1) && Rewarded(TrialsDone)) || ((correctSideRecord(TrialsDone)==2) && ~Rewarded(TrialsDone))
                ResponseSideRecord(TrialsDone) = 1;
            elseif ((correctSideRecord(TrialsDone)==1) && ~Rewarded(TrialsDone)) || ((correctSideRecord(TrialsDone)==2) && Rewarded(TrialsDone))
                ResponseSideRecord(TrialsDone) = 2;
            end
            
        end
        
        BpodSystem.Data.ResponseSide(TrialsDone) = ResponseSideRecord(TrialsDone);
        
        % If previous trial was not an early withdrawal, increase wait duration
        if ~BpodSystem.Data.EarlyWithdrawal(TrialsDone)
            S.minWaitTime = S.minWaitTime + S.minWaitTimeStep;
           
        end

        %print things to screen
        fprintf('Nr. of trials initiated: %d\n', TrialsDone)
        fprintf('Nr. of completed trials: %d\n', TrialsDone - nansum(EarlyWithdrawal)-nansum(DidNotChoose))
        fprintf('Nr. of rewards: %d\n', nansum(Rewarded))
        fprintf('Amount of water (est.): %d\n', nansum(Rewarded) * (mean([S.leftRewardVolume S.rightRewardVolume])))
        
        PerformancePlot(BpodSystem.GUIHandles.PerformancePlot, 'update', currentTrial, TrialSidesList, OutcomeRecord);
        
    end
    
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    
    % Save protocol settings file to directory
    SaveProtocolSettings(S);
    
    if BpodSystem.BeingUsed == 0
        BpodParameterGUI_Visual('close',S)
        return;
    end
    
end
end


% Auxillary functions

function generateAndUploadSounds (samplingFreq, soundLoudness)
% Star wait cue
waveStartSound = soundLoudness * GenerateSineWave(samplingFreq, 7000, 0.1); % Sampling freq (hz), Sine frequency (hz), duration (s)
WaitStartSound = [zeros(1,size(waveStartSound,2)); waveStartSound];

% Go cue
waveStopSound = soundLoudness * GenerateSineWave(samplingFreq, 3000, 0.1);
WaitStopSound = [zeros(1,size(waveStopSound,2)); waveStopSound];

% Early withdrawal punishment tone
% wavePunishSound = (rand(1,SamplingFreq*.5)*2) - 1;
wavePunishSound = 0.15 * soundLoudness * GenerateSineWave(samplingFreq, 12000, 1);
PunishSound = [zeros(1,size(wavePunishSound,2)); wavePunishSound];

% Upload sounds to sound server. Channel 1 reserved for stimuli
PsychToolboxSoundServer('Load', 2, WaitStartSound);
PsychToolboxSoundServer('Load', 3, WaitStopSound);
PsychToolboxSoundServer('Load', 4, PunishSound);
end

function UpdateOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if Data.Rewarded(x)
        Outcomes(x) = 1;
    elseif Data.EarlyWithdrawal(x)
        Outcomes(x) = -1;
    elseif Data.DidNotChoose(x)
        Outcomes(x) = -2;
    else
        Outcomes(x) = 0;
    end
end
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update', Data.nTrials+1, TrialTypes, Outcomes);drawnow
end

function [eventList,got_it]= getRandomStimEvents(thisRate, stimDuration, eventDuration)
frames = floor(stimDuration/eventDuration/2);
maxAttempts = 1000;
got_it = 0;
for attempt = 1:maxAttempts
    eventList = [1 (poissrnd(rand, 1, frames-1) > 0)];
    if sum(eventList) == thisRate
        got_it = 1;
        break;
    end
end

if ~got_it
    %try again to generate the stimulus, using higher lambda value.
    got_it = 0;
    for attempt = 1:maxAttempts
        eventList = [1 (poissrnd(5*rand, 1, frames-1) > 0)];
        if sum(eventList) == thisRate
            got_it = 1;
            break;
        end
    end
end


if ~got_it
    %if the attempts fail. do not present stimulus.
    disp('Not enough attempts to generate the desired stimulus');
    eventList = zeros(1,frames); % no stimulus
end

end

function waveform = buildAudioWaveForm(eventList, eventDuration, samplingFreq)
% white noise sound event
event_part = (rand(1,samplingFreq*eventDuration) * 2) - 1;
% event_part = 2*GenerateSineWave(samplingFreq, 1000, eventDuration);
silence_part = zeros(1,length(event_part));
waveform = [];
for ev = 1:length(eventList)
    this_event = eventList(ev);
    if this_event == 1
        waveform = [waveform event_part silence_part];
    else
        waveform = [waveform silence_part silence_part];
    end
end
end

function waveform = buildVisualWaveForm(eventList, eventDuration, samplingFreq, brightness)
% visual event
event_part = GenerateSineWave(samplingFreq, 200*brightness, eventDuration);
event_part(event_part < 0.5) = 0;
silence_part = zeros(1,length(event_part));
waveform = [];
for ev = 1:length(eventList)
    this_event = eventList(ev);
    if this_event == 1
        waveform = [waveform event_part silence_part];
    else
        waveform = [waveform silence_part silence_part];
    end
end
end


% Matt Kaufman's MOD solution for this is very elegant and works great.
function random_delay = generate_random_delay (lambda, minimum, maximum)
random_delay = 0;
if ~((minimum == 0) && (maximum ==0))
    x = -log(rand)/lambda;
    random_delay = mod(x, maximum - minimum) + minimum;
end
end



%Anti-bias functions from Matt Kaufman
function [newModeRightArray, newSuccessArray] = ...
    updateAntiBiasArrays(modeRightArray, successArray, visOrAud, outcome, ...
    prevCorrectSide, prevLR, prevSuccess, antiBiasTau, wentRight)
% Based on what happened on the last completed trial, update our beliefs
% about the animal's biases. modeRightArray tracks how likely he is to go
% right for each modality. successArray tracks how likely he is to succeed
% for left or right given what he did on the previous trial.
%
% Note: we'll actually use antiBiasTau * 3 for updating the
% modality-related side bias. If we don't, and there's only one modality,
% the updates will cause oscillation against a perfectly consistent
% strategy.

% For an exponential function, the pdf = (1/tau)*e^(-t/tau)
% The integral from 0 to 1 is [1 - e^(-1/tau)]
% This lets us do exponential decay using only the current
% outcome and previous biases
antiAlternationW = 1 - exp(-1/(3*antiBiasTau));
antiBiasW = 1 - exp(-1/antiBiasTau);

% modeRightArray -- how often he's gone right for each modality
% modality = 2 + visOrAud;
modality = visOrAud;
newModeRightArray = modeRightArray;
if ~isnan(wentRight)
    newModeRightArray(modality) = antiAlternationW * wentRight + (1 - antiAlternationW) * modeRightArray(modality);
end

% Can only update arrays if we already had a trial in the history (since we
% have a two-trial dependence)
newSuccessArray = successArray;
if ~isnan(prevLR)
    newSuccessArray(prevLR, prevSuccess + 1, prevCorrectSide) = antiBiasW * (outcome > 0) + ...
        (1-antiBiasW) * successArray(prevLR, prevSuccess + 1, prevCorrectSide);
end

end


function pLeft = getAntiBiasPLeft(successArray, modeRightArray, modality, ...
    antiBiasStrength, prevLR, prevSuccess)

% Find the relevant part of the SuccessArray and ModeRightArray
successPair = squeeze(successArray(prevLR, prevSuccess + 1, :));

modeRight = modeRightArray(modality);


% Based on the previous successes on this type of trial,
% preferentially choose the harder option

succSum = sum(successPair);

pLM = modeRight;  % prob desired for left based on modality-specific bias
pLT = successPair(2) / succSum;  % same based on prev trial
iVar2M = 1 / (pLM - 1/2) ^ 2; % inverse variance for modality
iVar2T = 1 / (pLT - 1/2) ^ 2; % inverse variance for trial history

if succSum == 0 || iVar2T > 10000
    % Handle degenerate cases, trial history uninformative
    pLeft = pLM;
elseif iVar2M > 10000
    % Handle degenerate cases, modality bias uninformative
    pLeft = pLT;
else
    % The interesting case... combine optimally
    pLeft = pLM * (iVar2T / (iVar2M + iVar2T)) + pLT * iVar2M / (iVar2M + iVar2T);
end

% Weight pLeft from anti-bias by antiBiasStrength
pLeft = antiBiasStrength * pLeft + (1 - antiBiasStrength) * 0.5;

end