%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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
function PerformancePlotK(AxesHandle, Action, varargin)
% Plugin for plotting performance over the course of the session.
% Currently plots 4 items: 
%             Fraction of Valid Trials - Average completed trials. Trials in which the subject completed (e.g. waited the required minimum time) did not
%                                        necessarily make the correct choice
%             Fraction of Correct Trials - Average successful trials,i.e the subject made the correct choice and was rewarded
%             Fraction of LEFT Trials -  Average success on LEFT trials
%             Fraction of RIGHT Trials - Average success on RIGHT trials

% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot
% Example usage:

%     PerformancePlot(AxesHandle,'init',CurrentTrial)  %set up axes nicely

%     PerformancePlot(AxesHandle,'update',CurrentTrial,TrialTypeSides,OutcomeRecord)
%     PerformancePlot(AxesHandle,'update',CurrentTrial,TrialTypeSides,OutcomeRecord,'colors',colors)

% varargins:
% TrialTypeSides: Vector of 0's (right) or 1's (left) to indicate reward side (0,1), or 'None' to plot trial types individually
% OutcomeRecord:  Vector of trial outcomes
%                 Simplest case: 
%                               1: correct trial (green)
%                               0: incorrect trial (red)
%                 Advanced case: 
%                               NaN: future trial (blue)
%                                -1: withdrawal (red circle)
%                                 0: incorrect choice (red dot)
%                                 1: correct choice (green dot)
%                                 2: did not choose (green circle)
% 'color': color flag
% colors: nx3 matrix, each row represents a color. eg. red = [1 0 0]
%         make sure there are enough rows for the items you plan to plot

% OutcomeRecord can also be empty
% Current trial: the current trial number

% Adapted from BControl (PerformancePlotSection.m) 
% Kachi O. 2014.Mar.17

global BpodSystem
global markersize ValidTrialsFractionVec PerformanceVec TrialType1Perf TrialType2Perf % makes these variable available to all cases 

markersize = 4;
switch Action
        
    case 'init'


         BpodSystem.GUIHandles.SessionTime = uicontrol('Style','text',...
        'Position',[0 20 200 20], 'String','Time: 0 min','Fontsize',13);
         
         BpodSystem.GUIHandles.DeliveredWater = uicontrol('Style','text',...
        'Position',[200 20 200 20], 'String','Water: 0 ul','Fontsize',13);
    
         BpodSystem.GUIHandles.CorrectTrials = uicontrol('Style','text',...
        'Position',[400 20 200 20], 'String','Correct trials: 0','Fontsize',13);

         BpodSystem.GUIHandles.ValidTrials = uicontrol('Style','text',...
        'Position',[600 20 200 20], 'String','Valid trials: 0','Fontsize',13);    
         
        BpodSystem.GUIHandles.TotalTrials = uicontrol('Style','text',...
        'Position',[800 20 200 20], 'String','Total trials: 0 ','Fontsize',13);
    
        BpodSystem.GUIHandles.WinLabel = uicontrol('Style','text',...
        'Position',[875 175 50 20], 'String','Win','Fontsize',13);
    
        BpodSystem.GUIHandles.Win = uicontrol('Style','edit',...
        'Position',[925 175 50 20], 'String',20,'Fontsize',13);
         
        BpodSystem.GUIHandles.nToPlotLabel = uicontrol('Style','text',...
        'Position',[875 150 50 20], 'String','N','Fontsize',13);
    
        BpodSystem.GUIHandles.nToPlot = uicontrol('Style','edit',...
        'Position',[925 150 50 20], 'String',100,'Fontsize',13);
    
        BpodSystem.GUIHandles.PerfLabel = uicontrol('Style','text',...
        'Position',[875 110 100 20], 'String','','Fontsize',13);
        
        max_trials = 2000;
        nToPlot = str2double(BpodSystem.GUIHandles.nToPlot.String);        
        
        ylabel(AxesHandle,'Performance');
        hold (AxesHandle,'on');
        indxToPlot = 1:max_trials;
        plot(AxesHandle,indxToPlot,0.5*ones(size(indxToPlot)),'k--')
        set(AxesHandle,'TickDir', 'out','XLim',[1 nToPlot],'YLim', [-0.1, 1.1], 'YTick', 0:0.25:1);
                
        PerformanceVec = nan(max_trials,1);
        TrialType1Perf = nan(max_trials,1);
        TrialType2Perf = nan(max_trials,1);
        ValidTrialsFractionVec = nan(max_trials,1);
        
         
    case 'update'

        lastTrial = varargin{1};
        SideList = varargin{2};
        OutcomeRecord = varargin{3};
        SessionBirthdate = tic;
        
        colors = [0.5 0.5 0.5;...%fraction of valid trials
                    0 1 0; ...   %fraction of correct trials
                    1 0.5 0; ... %fraction correct LEFT trials
                    0.5 0 1];    %fraction correct RIGHT trials
                
        nToPlot = str2double(BpodSystem.GUIHandles.nToPlot.String);
        Win = str2double(BpodSystem.GUIHandles.Win.String);
        
        PrevValidTrialsCount = sum(OutcomeRecord(1:lastTrial)>=0); %count number of valid (complete) trials
        SideList = SideList(OutcomeRecord >= 0);
        ValidTrials = OutcomeRecord(OutcomeRecord >= 0); %completed trials
        
        [mn,mx] = scaleX(AxesHandle,lastTrial,nToPlot);

         
        if lastTrial > 0
            %compute fraction of valid trials, i.e. complete trials (no early withdrawals)
            trialsToInclude = max(1,lastTrial -Win + 1 ): lastTrial; %in average
            indxToPlot = mn:mx;
            ValidTrialsFractionVec(lastTrial) = mean(OutcomeRecord(trialsToInclude) >= 0);
            h1 = plot(AxesHandle,indxToPlot,ValidTrialsFractionVec(indxToPlot),'s','MarkerFaceColor',colors(1,:),'MarkerEdgeColor', colors(1,:),'MarkerSize',markersize);

            %compute & plot total performance
            trialsToInclude = max(1,PrevValidTrialsCount - Win + 1):PrevValidTrialsCount; %for performance only use completed (valid) trials
            PerformanceVec(lastTrial) = mean(OutcomeRecord(trialsToInclude)== 1);
            h2 = plot(AxesHandle,indxToPlot,PerformanceVec(indxToPlot),'s','MarkerFaceColor',colors(2,:),'MarkerEdgeColor', colors(2,:),'MarkerSize',markersize);
            
            BpodSystem.GUIHandles.PerfLabel.String = num2str(PerformanceVec(lastTrial),'%2.0');
            
            %compute & plot performance for each trial type (i.e side)
            if ~isempty(SideList)
                
                TrialType1 = (SideList(trialsToInclude) == 1); %LEFT trials
                TrialType1Perf(lastTrial) = mean(ValidTrials(TrialType1)>0); %compute mean
                h3 = plot(AxesHandle,indxToPlot,TrialType1Perf(indxToPlot),'s','MarkerFaceColor',colors(3,:),'MarkerEdgeColor', colors(3,:),'MarkerSize',markersize); %plot
                
                TrialType2 = (SideList(trialsToInclude) == 0); %RIGHT trials
                TrialType2Perf(lastTrial) = mean(ValidTrials(TrialType2)>0); %compute mean
                h4 = plot(AxesHandle,indxToPlot,TrialType2Perf(indxToPlot),'s','MarkerFaceColor',colors(4,:),'MarkerEdgeColor', colors(4,:),'MarkerSize',markersize); %plot
                
            end

%             BpodSystem.GUIHandles.SessionTime.String = ['Time: ' num2str(toc(SessionBirthdate)/60,'%3.0f') ' min'];
%                         
%             BpodSystem.GUIHandles.DeliveredWater.String = ['Water: ' num2str(BpodSystem.Data.AccumulatedReward) ' ul'];
%             
%             BpodSystem.GUIHandles.ValidTrials.String = ['Valid trials: ' num2str(sum(OutcomeRecord >= 0))];
%             
%             BpodSystem.GUIHandles.CorrectTrials.String = ['Correct trials: ' num2str(sum(OutcomeRecord > 0))];
%             
%             BpodSystem.GUIHandles.TotalTrials.String = ['Total trials: ' num2str(sum(~isnan(OutcomeRecord)))];
try
            legend(AxesHandle,[h1,h2,h3,h4],'complete','correct','left','right','Location','South','Orientation','horizontal')
            legend(AxesHandle,'boxoff')
   
catch
    disp('')
end
            plot(AxesHandle,indxToPlot,0.5*ones(size(indxToPlot)),'k--')

        end

    
end

end


function [mn,mx] = scaleX(AxesHandle,lastTrial,NtrialsToPlot)


mx = max(lastTrial,NtrialsToPlot);
mn = max(1,mx-NtrialsToPlot+1);
NewXLim = [mn-0.5 mx+0.5];
set(AxesHandle, 'XLim', NewXLim);

end