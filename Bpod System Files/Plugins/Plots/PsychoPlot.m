function PsychoPlot(AxesHandle, Action, varargin)
%%
% Plug in to Plot Psychometric curve in real time
% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot

%Example usage:
% PsychoPlot(AxesHandle,'init')
% PsychoPlot(AxesHandle,'update',TrialTypeSides,OutcomeRecord)

% varargins:
% TrialTypeSides: Vector of 0's (right) or 1's (left) to indicate reward side (0,1), or 'None' to plot trial types individually
% OutcomeRecord:  Vector of trial outcomes
% EvidenceStrength: Vector of evidence strengths

% Adapted from BControl (PsychCurvePlotSection.m)
% F.Carnevale 2015.Feb.17

%% Code Starts Here
global bin_size %this is for convenience
global BpodSystem

switch Action
    case 'init'
        
        bin_size = 0.1;
        
        axes(AxesHandle);
        %plot in specified axes
        Xdata = -1:bin_size:1; Ydata=nan(1,size(Xdata,2));
        BpodSystem.GUIHandles.PsychometricLine = line([Xdata,Xdata],[Ydata,Ydata],'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace','k', 'MarkerSize',6);
        BpodSystem.GUIHandles.PsychometricData = [Xdata',Ydata'];
        set(AxesHandle,'TickDir', 'out', 'XLim', [-1, 1],'YLim', [0, 1], 'FontSize', 15);
        xlabel(AxesHandle, 'Evidence Strength', 'FontSize', 15);
        ylabel(AxesHandle, 'P(Right)', 'FontSize', 15);
        hold(AxesHandle, 'on');
        
    case 'update'
        try

        CurrentTrial = varargin{1};
        SideList = varargin{2};
        OutcomeRecord = varargin{3};
        pTarget =  varargin{4};
        
        %pTarget = (1/2+r/2);
        EvidenceStrength = 2*(pTarget-1/2);
        
        Xdata = BpodSystem.GUIHandles.PsychometricData(:,1);
        Ydata = BpodSystem.GUIHandles.PsychometricData(:,2);
        
        evidence_ind = round(EvidenceStrength/bin_size);
        
        if evidence_ind(CurrentTrial)>0 %evidence is nonzero 
            
            ntrials = sum(evidence_ind==evidence_ind(CurrentTrial) & SideList(1:CurrentTrial)==SideList(CurrentTrial) & OutcomeRecord(1:CurrentTrial)>=0);
            ntrials_correct = sum(evidence_ind==evidence_ind(CurrentTrial) & SideList(1:CurrentTrial)==SideList(CurrentTrial) & OutcomeRecord(1:CurrentTrial)==1);
            
            [p c] = binofit(ntrials_correct,ntrials);

            if SideList(CurrentTrial)==0 %0 is right
                Ydata((size(Xdata,1)-1)/2 + 1 + evidence_ind(CurrentTrial)) = p; %correct is right
            else %1 is left
                Ydata((size(Xdata,1)-1)/2 + 1 - evidence_ind(CurrentTrial)) = 1-p; %correct is left
            end
            
        else %evidence is zero, this assumes that SideList == 0 when the side is right
            
            ntrials = sum(evidence_ind==0 & OutcomeRecord(1:CurrentTrial)>=0);
            ntrials_right = sum(evidence_ind==0 & OutcomeRecord(1:CurrentTrial)>=0 & SideList(1:CurrentTrial)==0);
            
            [p c] = binofit(ntrials_right,ntrials);
            
            Ydata((size(Xdata,1)-1)/2 + 1) = p;
        
        end
        
        set(BpodSystem.GUIHandles.PsychometricLine, 'xdata', [Xdata], 'ydata', [Ydata]);
        
        BpodSystem.GUIHandles.PsychometricData(:,1) = Xdata;
        BpodSystem.GUIHandles.PsychometricData(:,2) = Ydata;
        
        set(AxesHandle,'XLim',[-1 1], 'Ylim', [0 1]);
        catch
            disp('')
        end
end

end

