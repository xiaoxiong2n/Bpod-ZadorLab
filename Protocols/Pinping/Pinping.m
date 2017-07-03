
function Pinping
% This protocol is used to estimate tuning curves in auditory areas
% Written by F.Carnevale, 4/2015.

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with settings default
    
    S.GUI.PulseWidth.panel = 'Pulse Settings'; S.GUI.PulseWidth.style = 'edit'; S.GUI.PulseWidth.string = 0.002; 
    
    S.GUI.minPulseFreq.panel = 'Pulse Settings'; S.GUI.minPulseFreq.style = 'edit'; S.GUI.minPulseFreq.string = 10; 
    S.GUI.maxPulseFreq.panel = 'Pulse Settings'; S.GUI.maxPulseFreq.style = 'edit'; S.GUI.maxPulseFreq.string = 100; 
    S.GUI.nFreq.panel = 'Pulse Settings'; S.GUI.nFreq.style = 'edit'; S.GUI.nFreq.string = 20; % Number of frequencies
    
    S.GUI.InterTrial.panel = 'Timing Settings'; S.GUI.InterTrial.style = 'edit'; S.GUI.InterTrial.string = 0.5; % Intertrial Interval
    S.GUI.PreStimMin.panel = 'Timing Settings'; S.GUI.PreStimMin.style = 'edit'; S.GUI.PreStimMin.string = 0.25; % PreSound Interval
    S.GUI.PreStimWidth.panel = 'Timing Settings'; S.GUI.PreStimWidth.style = 'edit'; S.GUI.PreStimWidth.string = 0.25; % PreSound Interval
    S.GUI.StimDuration.panel = 'Timing Settings'; S.GUI.StimDuration.style = 'edit'; S.GUI.StimDuration.string = 0.5; % Sound Duration
    S.GUI.nStim.panel = 'Timing Settings'; S.GUI.nStim.style = 'edit'; S.GUI.nStim.string = 10;
    
    S.GUI.PulseFreq.panel = 'Current Trial'; S.GUI.PulseFreq.style = 'text'; S.GUI.PulseFreq.string = 0; % Pulse Frequency
    S.GUI.TrialNumber.panel = 'Current Trial'; S.GUI.TrialNumber.style = 'text'; S.GUI.TrialNumber.string = 0; % Number of current trial
    S.GUI.TotalTrials.panel = 'Current Trial'; S.GUI.TotalTrials.style = 'text'; S.GUI.TotalTrials.string = 0; % Total number of trials
    
    % Other Stimulus settings (not in the GUI)
    StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
    
end

PulsePal;
load ParameterMatrix_Example;
ProgramPulsePal(ParameterMatrix); % Sends the default parameter matrix to Pulse Pal
ProgramPulsePalParam(1, 'LinkedToTriggerCH1', 0);
ProgramPulsePalParam(2, 'LinkedToTriggerCH1', 0);
ProgramPulsePalParam(3, 'LinkedToTriggerCH1', 0);
ProgramPulsePalParam(4, 'LinkedToTriggerCH1', 1); % Set output channel 4 to respond to trigger ch 1
%ProgramPulsePalParam(4, 'TriggerMode', 1); % Set trigger channel 1 to toggle mode

% Initialize parameter GUI plugin
EnhancedBpodParameterGUI('init', S);

BpodSystem.Data.TrialFreq = []; % The trial frequency of each trial completed will be added here.

% Notebook
BpodNotebook('init');

% Program sound server
PsychToolboxSoundServer('init')

% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'Tuning Curves Protocol...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin

%% Define trials
PossibleFreqs = linspace(S.GUI.minPulseFreq.string,S.GUI.maxPulseFreq.string,S.GUI.nFreq.string);

MaxTrials = size(PossibleFreqs,2)*S.GUI.nStim.string;

PulseFreq = PossibleFreqs(randi(size(PossibleFreqs,2),1,MaxTrials));

PreSound = nan(1,MaxTrials); % PreSound interval for each trial
InterTrial = nan(1,MaxTrials); % Intertrial interval for each trial
StimDuration = nan(1,MaxTrials); % Sound duration for each trial

S.GUI.PulseFreq.string = round(PulseFreq(1)); % Sound Volume

S.GUI.TrialNumber.string = 1; % Number of current trial
S.GUI.TotalTrials.string = MaxTrials; % Total number of trials

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
    
    InterTrial(currentTrial) = S.GUI.InterTrial.string;
    PreSound(currentTrial) = S.GUI.PreStimMin.string+S.GUI.PreStimWidth.string*rand;
    StimDuration(currentTrial) = S.GUI.StimDuration.string;

    % Update stimulus settings    
    StimulusSettings.PulseWidth = S.GUI.PulseWidth.string;    
    StimulusSettings.StimDuration = S.GUI.StimDuration.string;
    StimulusSettings.PulseFreq = PulseFreq(currentTrial);
    StimulusSettings.InterPulseInterval = round((1/StimulusSettings.PulseFreq)*10^4)/10^4;
    if StimulusSettings.InterPulseInterval <0
        StimulusSettings.InterPulseInterval = 0;
    end
    
    % This stage sound generation
%    Sound = GenerateSound(StimulusSettings);
%    PsychToolboxSoundServer('Load', 1, Sound);

    ProgramPulsePalParam(4, 'Phase1Voltage', 1); % Set output channel 1 to produce 2.5V pulses
    ProgramPulsePalParam(4, 'Phase1Duration', StimulusSettings.PulseWidth); % Set output channel 1 to produce 2ms pulses
    ProgramPulsePalParam(4, 'InterPulseInterval', StimulusSettings.InterPulseInterval); % Set pulse interval to produce 10Hz pulses
    ProgramPulsePalParam(4, 'PulseTrainDuration', StimulusSettings.StimDuration); % Set pulse train to last 120 seconds


    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = AddState(sma, 'Name', 'PreSound', ...
        'Timer', PreSound(currentTrial),...
        'StateChangeConditions', {'Tup', 'TrigStart'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TrigStart', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'DeliverStimulus'},...
        'OutputActions', {'BNCState', 2});
    sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', StimDuration(currentTrial)/1000,...
        'StateChangeConditions', {'Tup', 'InterTrial'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'InterTrial', ...
        'Timer', InterTrial(currentTrial),...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.PulseFreq(currentTrial) = PulseFreq(currentTrial);
        BpodSystem.Data.StimDuration(currentTrial) = StimDuration(currentTrial);
        BpodSystem.Data.InterTrial(currentTrial) = InterTrial(currentTrial);
        BpodSystem.Data.PreSound(currentTrial) = PreSound(currentTrial);
        BpodSystem.Data.StimulusSettings = StimulusSettings; % Save Stimulus settings
        
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        if currentTrial<MaxTrials
            
            PossibleFreqs = linspace(S.GUI.minPulseFreq.string,S.GUI.maxPulseFreq.string,S.GUI.nFreq.string);
            PulseFreq(currentTrial+1:end) = PossibleFreqs(randi(size(PossibleFreqs,2),1,MaxTrials-currentTrial));
            
            % display next trial info
            S.GUI.PulseFreq.string = round(PulseFreq(currentTrial+1));
            S.GUI.TrialNumber.string = currentTrial+1; % Number of current trial
            S.GUI.TotalTrials.string = MaxTrials; % Total number of trials
        end
        
    end
    
    if BpodSystem.BeingUsed == 0
        return
    end
    
end
