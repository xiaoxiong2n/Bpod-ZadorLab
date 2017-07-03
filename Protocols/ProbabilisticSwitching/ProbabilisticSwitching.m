%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function ProbabilisticSwitching

% SETUP
% You will need:
% - A Bpod MouseBox (or equivalent) configured with 3 ports.
% > Connect the left port in the box to Bpod Port#1.
% > Connect the center port in the box to Bpod Port#2.
% > Connect the right port in the box to Bpod Port#3.
% > Make sure the liquid calibration tables for ports 1 and 3 have 
%   calibration curves with several points surrounding 3ul.

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.Subject.panel = 'Protocol'; S.GUI.Subject.style = 'text'; S.GUI.Subject.string = BpodSystem.GUIData.SubjectName;    
        
    S.GUI.Stage.panel = 'Protocol'; S.GUI.Stage.style = 'popupmenu'; S.GUI.Stage.string = {'Direct', 'Task'};S.GUI.Stage.value = 2;
        
    S.GUI.RewardAmount.panel = 'Reward'; S.GUI.RewardAmount.style = 'edit'; S.GUI.RewardAmount.string = 3;        
    S.GUI.CenterRewardAmount.panel = 'Reward'; S.GUI.CenterRewardAmount.style = 'edit'; S.GUI.CenterRewardAmount.string = 0.5;
    S.GUI.RewardProbability.panel = 'Reward'; S.GUI.RewardProbability.style = 'edit'; S.GUI.RewardProbability.string = 1;    
    
    S.GUI.BlockLengthMin.panel = 'Trial Structure'; S.GUI.BlockLengthMin.style = 'edit'; S.GUI.BlockLengthMin.string = 20;
    S.GUI.BlockLengthMax.panel = 'Trial Structure'; S.GUI.BlockLengthMax.style = 'edit'; S.GUI.BlockLengthMax.string = 30;
    S.GUI.CueDelay.panel = 'Trial Structure'; S.GUI.CueDelay.style = 'edit'; S.GUI.CueDelay.string = 0.02;    
    S.GUI.ResponseTime.panel = 'Trial Structure'; S.GUI.ResponseTime.style = 'edit'; S.GUI.ResponseTime.string = 5;
    S.GUI.PunishDelay.panel = 'Trial Structure'; S.GUI.PunishDelay.style = 'edit'; S.GUI.PunishDelay.string = 0;    
    
    S.GUI.LightCue.panel = 'Trial Structure'; S.GUI.LightCue.style = 'checkbox'; S.GUI.LightCue.string = 'Light Cue'; S.GUI.LightCue.value = 1;
end

% Initialize parameter GUI plugin
EnhancedBpodParameterGUI('init', S);

% Total Reward display (online display of the total amount of liquid reward earned)
TotalRewardDisplay('init');


%% Define trials
MaxTrials = 5000;
TrialTypes = nan(1,MaxTrials);

BpodSystem.ProtocolFigures.InitialMsg = msgbox({'', ' Edit your settings and click OK when you are ready to start!     ', ''},'ToneCloud Protocol...');
uiwait(BpodSystem.ProtocolFigures.InitialMsg);

S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin

BlockLengthMax = S.GUI.BlockLengthMax.string;
BlockLengthMin = S.GUI.BlockLengthMin.string;

i=0; 
while i<MaxTrials

    %block 1 (rewarded port 1)
    aux1 = randi(BlockLengthMax-BlockLengthMin+1)+BlockLengthMin-1;
    TrialTypes(i+1:i+aux1)=1;
    i=i+aux1;
    
    %block 2 (rewarded port 3)
    aux2 = randi(BlockLengthMax-BlockLengthMin+1)+BlockLengthMin-1;
    TrialTypes(i+1:i+aux2)=2;
    i=i+aux2;
end
TrialTypes = TrialTypes(1,1:MaxTrials);

TrialRewarded = nan(1,MaxTrials);

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.TrialRewarded = []; % The trial type of each trial completed will be added here.

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [457 803 1000 250],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',2-TrialTypes);



%% Main trial loop
BlockIndex=1;

for currentTrial = 1:MaxTrials
    
    
    S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount.string, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    C = GetValveTimes(S.GUI.CenterRewardAmount.string, 2); CenterValveTime = C(1);
    
    switch 1
        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Direct')
        
            S.GUI.RewardProbability.string=1;
            S = EnhancedBpodParameterGUI('sync', S); % Sync parameters with EnhancedBpodParameterGUI plugin
    end
    
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1 % left port is rewarded 
            if rand<S.GUI.RewardProbability.string 
                LeftActionState = 'Reward';
                TrialRewarded(currentTrial)=1;
            else
                LeftActionState = 'Unrewarded';
                TrialRewarded(currentTrial)=0;
            end
            LightOn = 'PWM1';
            RightActionState = 'Wrong';
            ValveTime = LeftValveTime;
            ValveState = 1;
        case 2
            if rand<S.GUI.RewardProbability.string 
                RightActionState = 'Reward';
                TrialRewarded(currentTrial)=1;
            else
                RightActionState = 'Unrewarded';
                TrialRewarded(currentTrial)=0;
            end
            LightOn = 'PWM3';
            LeftActionState = 'Wrong';
            ValveTime = RightValveTime;
            ValveState = 4;
    end
    
    CenterValveState = 2;
    sma = NewStateMatrix(); % Assemble state matrix
    
    
    switch 1

        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Direct')
            
            sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port2In', 'CenterDelay'},...
                'OutputActions', {}); 
            sma = AddState(sma, 'Name', 'CenterDelay', ...
                'Timer', S.GUI.CueDelay.string,...
                'StateChangeConditions', {'Port2Out', 'WaitForCenterPoke', 'Tup', 'WaitForCenterOut'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'WaitForCenterOut', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port2Out', 'Reward'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'WaitForResponse'},...
                'OutputActions', {'ValveState', ValveState}); 
            sma = AddState(sma, 'Name', 'WaitForResponse', ...
                'Timer', S.GUI.ResponseTime.string,...
                'StateChangeConditions', {'Port1In', 'Drinking', 'Port3In', 'Drinking', 'Tup', 'exit'},...
                'OutputActions', {});             
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1Out', 'exit', 'Port3Out', 'exit'},...
                'OutputActions', {});
        
        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Task') % Full task
            
            sma = AddState(sma, 'Name', 'WaitForCenterPoke', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port2In', 'CenterDelay'},...
                'OutputActions', {'PWM2', 255}); 
            sma = AddState(sma, 'Name', 'CenterDelay', ...
                'Timer', S.GUI.CueDelay.string,...
                'StateChangeConditions', {'Port2Out', 'WaitForCenterPoke', 'Tup', 'CenterReward'},...
                'OutputActions', {'PWM2', 255});
            
            if S.GUI.LightCue.value
            
                sma = AddState(sma, 'Name', 'CenterReward', ...
                    'Timer', CenterValveTime,...
                    'StateChangeConditions', {'Tup', 'WaitForCenterOut'},...
                    'OutputActions', {'ValveState', CenterValveState, LightOn, 255});
                sma = AddState(sma, 'Name', 'WaitForCenterOut', ...
                    'Timer', 0,...
                    'StateChangeConditions', {'Port2Out', 'WaitForResponse'},...
                    'OutputActions', {LightOn, 255});            
                sma = AddState(sma, 'Name', 'WaitForResponse', ...
                    'Timer', S.GUI.ResponseTime.string,...
                    'StateChangeConditions', {'Port1In', LeftActionState, 'Port3In', RightActionState, 'Tup', 'exit'},...
                    'OutputActions', {LightOn, 255}); 
            else
            
                sma = AddState(sma, 'Name', 'CenterReward', ...
                    'Timer', CenterValveTime,...
                    'StateChangeConditions', {'Tup', 'WaitForCenterOut'},...
                    'OutputActions', {'ValveState', CenterValveState,'PWM1', 255, 'PWM3', 255});
                sma = AddState(sma, 'Name', 'WaitForCenterOut', ...
                    'Timer', 0,...
                    'StateChangeConditions', {'Port2Out', 'WaitForResponse'},...
                    'OutputActions', {'PWM1', 255, 'PWM3', 255});            
                sma = AddState(sma, 'Name', 'WaitForResponse', ...
                    'Timer', S.GUI.ResponseTime.string,...
                    'StateChangeConditions', {'Port1In', LeftActionState, 'Port3In', RightActionState, 'Tup', 'exit'},...
                    'OutputActions', {'PWM1', 255, 'PWM3', 255});                
                
            end
            
            sma = AddState(sma, 'Name', 'Reward', ...
                'Timer', ValveTime,...
                'StateChangeConditions', {'Tup', 'Drinking'},...
                'OutputActions', {'ValveState', ValveState}); 
            sma = AddState(sma, 'Name', 'Unrewarded', ...
                'Timer', 0,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions',{}); 
            sma = AddState(sma, 'Name', 'Drinking', ...
                'Timer', 0,...
                'StateChangeConditions', {'Port1Out', 'exit', 'Port3Out', 'exit'},...
                'OutputActions', {});
            sma = AddState(sma, 'Name', 'Wrong', ...
                'Timer', S.GUI.PunishDelay.string,...
                'StateChangeConditions', {'Tup', 'exit'},...
                'OutputActions', {});
    end
        
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        BpodSystem.Data.TrialRewarded(currentTrial) = TrialRewarded(currentTrial); % Adds the trial type of the current trial to data
        
        %Outcome
        switch 1

        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Direct')
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking(1))
                Outcomes(currentTrial) = 1;
            else
                Outcomes(currentTrial) = 0;
            end
            
        case strfind(S.GUI.Stage.string(S.GUI.Stage.value),'Task') % Full task    
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking(1))
                Outcomes(currentTrial) = 1;
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Wrong(1))
                Outcomes(currentTrial) = 0;
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Unrewarded(1))
                Outcomes(currentTrial) = 2;
            else
                Outcomes(currentTrial) = 3;
            end
            
        end
        
        BpodSystem.Data.Outcomes(currentTrial) = Outcomes(currentTrial);
        UpdateTotalRewardDisplay(S.GUI.RewardAmount.string, currentTrial);
        UpdateOutcomePlot(TrialTypes, Outcomes);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
    if BpodSystem.BeingUsed == 0
        return
    end
end

function UpdateOutcomePlot(TrialTypes, Outcomes)
global BpodSystem
EvidenceStrength = 0;
nTrials = BpodSystem.Data.nTrials;
OutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',nTrials+1,2-TrialTypes,Outcomes,EvidenceStrength);

function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% If rewarded based on the state data, update the TotalRewardDisplay
global BpodSystem
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
        TotalRewardDisplay('add', RewardAmount);
    end