
function TuningCurves
% This protocol is used to estimate tuning curves in auditory areas
% Written by F.Carnevale, 4/2015.

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with settings default
    
    S.GUI.SoundType.panel = 'Sound Settings'; S.GUI.SoundType.style = 'popupmenu'; S.GUI.SoundType.string = {'Tone', 'Chord','FM','Noise','FastBips'}; S.GUI.SoundType.value = 1;
    
    S.GUI.LowFreq.panel = 'Sound Settings'; S.GUI.LowFreq.style = 'edit'; S.GUI.LowFreq.string = 4000; % Lowest frequency
    S.GUI.HighFreq.panel = 'Sound Settings'; S.GUI.HighFreq.style = 'edit'; S.GUI.HighFreq.string = 40000; % Highest frequency
    S.GUI.nFreq.panel = 'Sound Settings'; S.GUI.nFreq.style = 'edit'; S.GUI.nFreq.string = 20; % Number of frequencies    

    S.GUI.SoundVolumeMin.panel = 'Sound Settings'; S.GUI.SoundVolumeMin.style = 'edit'; S.GUI.SoundVolumeMin.string = 55; % Sound Volume    
    S.GUI.SoundVolumeMax.panel = 'Sound Settings'; S.GUI.SoundVolumeMax.style = 'edit'; S.GUI.SoundVolumeMax.string = 55; % Sound Volume
    S.GUI.nVolumes.panel = 'Sound Settings'; S.GUI.nVolumes.style = 'edit'; S.GUI.nVolumes.string = 1; % Number of sound volumes
    
    S.GUI.InterTrial.panel = 'Timing Settings'; S.GUI.InterTrial.style = 'edit'; S.GUI.InterTrial.string = 0.5; % Intertrial Interval
    S.GUI.PreSoundMin.panel = 'Timing Settings'; S.GUI.PreSoundMin.style = 'edit'; S.GUI.PreSoundMin.string = 0.5; % PreSound Interval
    S.GUI.PreSoundWidth.panel = 'Timing Settings'; S.GUI.PreSoundWidth.style = 'edit'; S.GUI.PreSoundWidth.string = 0.25; % PreSound Interval
    S.GUI.SoundDuration.panel = 'Timing Settings'; S.GUI.SoundDuration.style = 'edit'; S.GUI.SoundDuration.string = 0.25; % Sound Duration
    S.GUI.nSounds.panel = 'Timing Settings'; S.GUI.nSounds.style = 'edit'; S.GUI.nSounds.string = 20;
    
    S.GUI.SoundFreq.panel = 'Current Trial'; S.GUI.SoundFreq.style = 'text'; S.GUI.SoundFreq.string = 0; % Sound Frequency
    S.GUI.SoundVolume.panel = 'Current Trial'; S.GUI.SoundVolume.style = 'text'; S.GUI.SoundVolume.string = 0; % Sound Volume
    S.GUI.TrialNumber.panel = 'Current Trial'; S.GUI.TrialNumber.style = 'text'; S.GUI.TrialNumber.string = 0; % Number of current trial

    S.GUI.BregmaAP.panel = 'Coordinates'; S.GUI.BregmaAP.style = 'edit'; S.GUI.BregmaAP.string = 0; %
    S.GUI.BregmaDM.panel = 'Coordinates'; S.GUI.BregmaDM.style = 'edit'; S.GUI.BregmaDM.string = 0; %
    S.GUI.SurfaceDepth.panel = 'Coordinates'; S.GUI.SurfaceDepth.style = 'edit'; S.GUI.SurfaceDepth.string = 0; %
    
    S.GUI.ElectrodeAP.panel = 'Coordinates'; S.GUI.ElectrodeAP.style = 'edit'; S.GUI.ElectrodeAP.string = 0; %
    S.GUI.ElectrodeDM.panel = 'Coordinates'; S.GUI.ElectrodeDM.style = 'edit'; S.GUI.ElectrodeDM.string = 0; %
    S.GUI.ElectrodeDepth.panel = 'Coordinates'; S.GUI.ElectrodeDepth.style = 'edit'; S.GUI.ElectrodeDepth.string = 0; %
    
    % Other Stimulus settings (not in the GUI)
    StimulusSettings.SamplingRate = 192000; % Sound card sampling rate;
    StimulusSettings.Ramp = 0.005; 
    
end

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
PossibleFreqs = logspace(log10(S.GUI.LowFreq.string),log10(S.GUI.HighFreq.string),S.GUI.nFreq.string);
PossibleVolumes = linspace(S.GUI.SoundVolumeMin.string,S.GUI.SoundVolumeMax.string,S.GUI.nVolumes.string);

MaxTrials = size(PossibleFreqs,2)*S.GUI.nSounds.string;

TrialFreq = PossibleFreqs(randi(size(PossibleFreqs,2),1,MaxTrials));
TrialVol = PossibleVolumes(randi(size(PossibleVolumes,2),1,MaxTrials));

PreSound = nan(1,MaxTrials); % PreSound interval for each trial
InterTrial = nan(1,MaxTrials); % Intertrial interval for each trial
SoundDuration = nan(1,MaxTrials); % Sound duration for each trial

S.GUI.SoundFreq.string = round(TrialFreq(1)); % Sound Freq
S.GUI.SoundVolume.string = round(TrialVol(1)); % Sound Freq
S.GUI.TrialNumber.string = [num2str(1) '/' num2str(MaxTrials)]; % Number of current trial

%% Main trial loop
for currentTrial = 1:MaxTrials
    
    S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
    
    InterTrial(currentTrial) = S.GUI.InterTrial.string;
    PreSound(currentTrial) = S.GUI.PreSoundMin.string+S.GUI.PreSoundWidth.string*rand;
    SoundDuration(currentTrial) = S.GUI.SoundDuration.string;

    % Update stimulus settings    
    StimulusSettings.SoundVolume = TrialVol(currentTrial);
    StimulusSettings.SoundDuration = S.GUI.SoundDuration.string;
    StimulusSettings.Freq = TrialFreq(currentTrial);
    StimulusSettings.Ramp =     StimulusSettings.Ramp;
    
    % This stage sound generation
    Sound = GenerateSound(StimulusSettings);
    PsychToolboxSoundServer('Load', 1, Sound);
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = AddState(sma, 'Name', 'PreSound', ...
        'Timer', PreSound(currentTrial),...
        'StateChangeConditions', {'Tup', 'TrigStart'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'TrigStart', ...
        'Timer', 0.01,...
        'StateChangeConditions', {'Tup', 'DeliverStimulus'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', SoundDuration(currentTrial),...
        'StateChangeConditions', {'Tup', 'InterTrial'},...
        'OutputActions', {'SoftCode', 1, 'BNCState', 1});
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
        BpodSystem.Data.TrialFreq(currentTrial) = TrialFreq(currentTrial);
        BpodSystem.Data.TrialVol(currentTrial) = TrialVol(currentTrial);
        BpodSystem.Data.SoundDuration(currentTrial) = SoundDuration(currentTrial);
        BpodSystem.Data.InterTrial(currentTrial) = InterTrial(currentTrial);
        BpodSystem.Data.PreSound(currentTrial) = PreSound(currentTrial);
        BpodSystem.Data.StimulusSettings = StimulusSettings; % Save Stimulus settings
        
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        if currentTrial<MaxTrials
            
            PossibleFreqs = logspace(log10(S.GUI.LowFreq.string),log10(S.GUI.HighFreq.string),S.GUI.nFreq.string);
            TrialFreq(currentTrial+1:end) = PossibleFreqs(randi(size(PossibleFreqs,2),1,MaxTrials-currentTrial));
            
            % display next trial info
            S.GUI.SoundFreq.string = round(TrialFreq(currentTrial+1)); % Sound Frequency
            S.GUI.SoundVolume.string = round(TrialVol(currentTrial+1)); % Sound Volume
            S.GUI.TrialNumber.string = [num2str(currentTrial+1) '/' num2str(MaxTrials)]; % Number of current trial
        end
        
    end
    
    if BpodSystem.BeingUsed == 0
        return
    end
    
end
