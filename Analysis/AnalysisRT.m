clear
close all
clc

font_size = 12;
figure_size = [4 3];

subjectpath = '../Data';

%subject_prefix = 'FT';
%protocol = 'ToneCloudsFixedTime';

subject_prefix = 'RT';
protocol = 'ToneClouds4BPod';


time = clock;
date_time = [date '-' num2str(time(4)) '-' num2str(time(5))];
result_path = ['~/../../media/fede/Data/Data-on-Satellite/AAAApostdoc/zador/research/b-pod/Results/behavior-' subject_prefix '-' date_time '/'];
mkdir(result_path);


subjects = dir([subjectpath '/' subject_prefix '*']);
subjects={subjects.name}'; %session files ordered by date
n_subjects = size(subjects,1);



for m=1:n_subjects

    subject = subjects{m,:};

    datapath = ['../Data/' subject '/' protocol '/Session Data/'];

    files = dir([datapath '/*.mat']);
    [ignore,idx]=sort([files.datenum]);
    files={files(idx).name}'; %session files ordered by date

    nSessions = size(files,1);

    nTrials = cell(nSessions,1);
    sideList = cell(nSessions,1);
    outcomeRecord = cell(nSessions,1);
    evidenceStrength = cell(nSessions,1);
    n_difficulties = nan(nSessions,1);
    cloud = cell(nSessions,1);
    rawEvents = cell(nSessions,1);
    task = cell(nSessions,1);
    for i=1:size(files,1)

        try
            load([datapath files{i,:}])
        catch
            disp(['Couldn`t load file: ' files{i,:}])
%             break
        end

        nTrials{i,1} = size(SessionData.TrialTypes,2);
        sideList{i,1} = SessionData.TrialTypes;
        outcomeRecord{i,1} = SessionData.Outcomes;
        evidenceStrength{i,1} =  SessionData.EvidenceStrength;
        n_difficulties(i,1) =  size(unique(SessionData.EvidenceStrength),2);
        cloud{i,1} =  SessionData.Cloud;
        rawEvents{i,1} = SessionData.RawEvents.Trial;
        task{i,1} = char(SessionData.TrialSettings(1,1).GUI.Stage.string(SessionData.TrialSettings(1,1).GUI.Stage.value));
    end

    % conserve only 'full task' sessions
    fulltask = strcmp(task,'Full task');
    nSessions = sum(fulltask);
    nTrials = nTrials(fulltask);
    sideList = sideList(fulltask);
    outcomeRecord = outcomeRecord(fulltask);
    evidenceStrength = evidenceStrength(fulltask);
    n_difficulties = n_difficulties(fulltask);
    cloud = cloud(fulltask);
    rawEvents = rawEvents(fulltask);
    task = task(fulltask);


    % loop for analysis in each session
    psycho_x = cell(nSessions,1);
    psycho = cell(nSessions,1);
    psycho_fit = cell(nSessions,1);
    psycho_regress = cell(nSessions,1);
    psycho_logit = cell(nSessions,1);
    psycho_kernel = cell(nSessions,1);
    psycho_kernel_bstp = cell(nSessions,1);
    psycho_kernel_freq = cell(nSessions,1);
    performance  = cell(nSessions,1);
    evidence_power = cell(nSessions,1);
    valid  = cell(nSessions,1);
    mean_performance = nan(1,nSessions);
    mean_valid = nan(1,nSessions);
    response_time = cell(nSessions,1);
    for i=1:nSessions

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Psychometric
        warmup = 50;
        cooldown = 10;
        to_include = warmup:nTrials{i,1}-cooldown;
        x = evidenceStrength{i,1}(to_include); % stimulus strengh
        y = outcomeRecord{i,1}(to_include); % trial outcome (0=incorrect, 1=correct, -1=invalid)
        side = sideList{i,1}(to_include); % correct side
        n_bins = 10; % number of bins in each choice excluding 0 evidence
        psycho{i,1} = psychofcn(x,y,side,n_bins);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % fitting psycho curve
        x = psycho{i,1}.x;
        y = psycho{i,1}.y;
        [b,bint,r,rint,stats] = regress(log(y'./(1-y')),[ones(size(x,2),1) x']) ;
        psycho_regress{i,1} = b;%1./(1+exp(-(b(1)+b(2)*x)));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % logistic regression
        to_include = outcomeRecord{i,1}~=-1;
        to_include = logical([zeros(1,warmup) to_include(warmup+1:nTrials{i,1}-cooldown) zeros(1,cooldown)]);
        x = (2*sideList{i,1}(to_include)-3)'.*evidenceStrength{i,1}(to_include)';
        y = (sideList{i,1}(to_include)-1)'== outcomeRecord{i,1}(to_include)';
        [b,dev,stats] = glmfit(x,y,'binomial','link','logit');
        psycho_logit{i,1} = b;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % psychophysical kernel
        
        if n_difficulties(i,1)>=5 %only makes sense for psychometric sessions
        
            max_t = 50; % max number of tones, which I don't know in advace. not the most efficient way...
            minTrial = 50;
            for t=1:max_t
                
                s=nan(nTrials{i,1},1);
                for j=1:nTrials{i,1}
                    if diff(rawEvents{i,1}{1,j}.States.DeliverStimulus) > t*SessionData.TrialSettings(1,j).GUI.ToneDuration.string
                        if size(cloud{i,1}{1,j},2)>=t
                            s(j,1) = cloud{i,1}{1,j}(1,t);
                        end
                    end
                end
                
                if sum(~isnan(s)) > minTrial
                    
                    to_include = outcomeRecord{i,1}~=-1;
                    to_include = logical([zeros(1,warmup) to_include(warmup+1:nTrials{i,1}-cooldown) zeros(1,cooldown)]);
                    
                    %%% kernel with frequency (1 or -1)
                    x = s(to_include)>9.5;
                    x = 2*(s(to_include)>9.5)-1;
                    %                 x = (x-nanmean(x))./nanstd(x);
                    y = (sideList{i,1}(to_include)-1)'== outcomeRecord{i,1}(to_include)';
                    [b,dev,stats] = glmfit(x,y,'binomial','link','logit');
                    psycho_kernel{i,1}(:,t) = b;
                    for k=1:50
                        [b,dev,stats] = glmfit(x,y(randperm(size(y,1))),'binomial','link','logit');
                        psycho_kernel_bstp{i,1}(k,t) = b(2);
                    end
                    
                    %                 yfit = glmval(psycho_kernel{i,1}(:,t),x,'logit');
                    %                 plot(x,yfit,'b')
                    %                 hold on
                    %                 plot(psycho{i,1}.x,psycho{i,1}.y,'o')
                    %                x = -1:0.1:1;
                    %                 yfit = glmval(psycho_logit{i,1},x,'logit');
                    %                 plot(x,yfit,'r')
                    
                    
                    %%% kernel with the index of frequency
                    x = 0*ones(sum(to_include),18);
                    to_include_indx = find(to_include);
                    for k=1:sum(to_include)
                        if ~isnan(s(to_include_indx(k),1))
                            x(k,s(to_include_indx(k),1))=1;
                        end
                    end
                    %                 x = bsxfun(@minus, x, mean(x));
                    %                 x = bsxfun(@rdivide, x, nanstd(x,0,1));
                    y = (sideList{i,1}(to_include)-1)'== outcomeRecord{i,1}(to_include)';
                    try
                        [b,dev,stats] = glmfit([x(:,1:6) x(:,13:18)],y,'binomial','link','logit');
                    catch ME%catch ill-conditioned X and max number of iterations
                        b = nan(13,1);
                    end
                    psycho_kernel_freq{i,1}(:,t) = b;
                    
                else
                    psycho_kernel{i,1}(:,t) = nan(2,1);
                    psycho_kernel_freq{i,1}(:,t) = nan(13,1);
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Response time
        response_time{i,1} = nan(nTrials{i,1},1);
        for j=1:nTrials{i,1}
%             switch outcomeRecord{i,1}(1,j)
%                 case 1
%                     response_time{i,1}(1,j) = rawEvents{i,1}{1,j}.States.Reward(1)-rawEvents{i,1}{1,j}.States.WaitForResponse(1);
%                 case 0
%                     response_time{i,1}(1,j) = rawEvents{i,1}{1,j}.States.Punish(1)-rawEvents{i,1}{1,j}.States.WaitForResponse(1);
%                 otherwise
%                     response_time{i,1}(1,j) = 0/0;
%             end
            response_time{i,1}(j,1) = rawEvents{i,1}{1,j}.States.DeliverStimulus(2)-rawEvents{i,1}{1,j}.States.DeliverStimulus(1);  
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Performance
        performance{i,1} = nan(nTrials{i,1},1);
        win_width = 20;
        outcome = outcomeRecord{i,1};
        %convolution with sliding window ignoring non valid trials
        for j=1:nTrials{i,1}-win_width
            a = outcome(j:j+win_width); %proportion of correct over valid
            performance{i,1}(j,1) = sum(a>0)/sum(a>=0);
        end
        a = outcome(1:end);
        mean_performance(1,i) = mean(sum(a>0)/sum(a>=0));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Valid trials
        valid{i,1} = nan(nTrials{i,1},1);
        win_width = 20;
        outcome = outcomeRecord{i,1};
        %convolution with sliding window
        for j=1:nTrials{i,1}-win_width
            a = outcome(j:j+win_width); % proportion of valid over all trials
            valid{i,1}(j,1) = sum(a>=0)/sum(a>=-1);
        end
        a = outcome(1:end);

        mean_valid(1,i) = mean(sum(a>=0)/sum(a>=-1));   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% response time distribution
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    for i=1:nSessions
        subplot(floor(sqrt(nSessions)),ceil(nSessions/floor(sqrt(nSessions))),i)
        hold on
        [n x] = hist(response_time{i,1});
        f=n;
        bar(x,f,'barwidth',0.7,'edgecolor',[1 0.5 0],'facecolor',[0.9 0.4 0],'linewidth',1.5)  
        set(gca,'FontSize',font_size)
        if i==1
            xlabel('Response time','FontSize',font_size)
            ylabel('% Trials','FontSize',font_size)
            title('rt_distribution')
        end
    end
    print('-dpng', [result_path subject '_RTdistribution.png']);
    print('-dpdf', [result_path subject '_RTdistribution.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% psychometric
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    for i=1:nSessions
        subplot(floor(sqrt(nSessions)),ceil(nSessions/floor(sqrt(nSessions))),i)
        hold on
        plot(psycho{i,1}.x,psycho{i,1}.y,'o','MarkerEdgeColor','none','MarkerFaceColor',[i/nSessions 0 1-i/nSessions])
        
        %%%psycho regress
        x = -1:0.1:1;
        b = psycho_regress{i,1};
        y = 1./(1+exp(-(b(1)+b(2)*x)));        
        plot(x,y,'k');        

        x = -1:0.1:1;
        if ~isempty(psycho_logit{i,1})
            yfit = glmval(psycho_logit{i,1},x,'logit');
            plot(x,yfit,'b')
        end
        
        axis([-1 1 0 1])
        set(gca,'FontSize',font_size)
        if i==1
            xlabel('Evidence Strengh','FontSize',font_size)
            ylabel('% Trials','FontSize',font_size)
            title('Psychometric curves')
        end
    end
    print('-dpng', [result_path subject '_psychometric.png']);
    print('-dpdf', [result_path subject '_psychometric.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% psychophysical kernel
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    nSessions_psycho = sum(n_difficulties>=5);
    k=0;
    for i=1:nSessions
        if n_difficulties(i,1)>=5
            k=k+1;
            subplot(floor(sqrt(nSessions_psycho)),ceil(nSessions_psycho/floor(sqrt(nSessions_psycho))),k)
            hold on
            plot(psycho_kernel_bstp{i,1},'color',[0.7 0.7 0.7],'linewidth',0.5)
            axis([1 sum(~isnan(psycho_kernel{i,1}(1,:))) -0.5 3])
            xlim = get(gca,'Xlim');
            ylim = get(gca,'Ylim');
            plot(psycho_kernel{i,1}(2,:),'color',[0.1 0.1 0.8],'linewidth',1.5)
            plot(xlim,[1 1]*psycho_logit{i,1}(2,:),'color',[0.75 0.5 0.25],'linewidth',0.5)
            if i==1
                xlabel('Time','FontSize',font_size)
                ylabel('Coeff','FontSize',font_size)
            end
            if i==round(0.5*sqrt(nSessions)), title('Psychophysical Kernel'); end
            set(gca,'FontSize',font_size)
        end
    end
    print('-dpng', [result_path subject '_psychokernel.png']);
    print('-dpdf', [result_path subject '_psychokernel.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% psychophysical kernel with freq
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    nSessions_psycho = sum(n_difficulties>=5);
    k=0;
    for i=1:nSessions
        if n_difficulties(i,1)>=5
            k=k+1;
            subplot(floor(sqrt(nSessions_psycho)),ceil(nSessions_psycho/floor(sqrt(nSessions_psycho))),k)
            hold on
            imagesc(psycho_kernel_freq{i,1}(2:end,:))
            try
                axis([1 sum(~isnan(psycho_kernel_freq{i,1}(1,:))) 1 12])
            catch
                axis([1 16 1 12])    
            end
            if i==1
                xlabel('','FontSize',font_size)
                ylabel('','FontSize',font_size)
            end
            if i==round(0.5*sqrt(nSessions)), title('Psychophysical Kernel'); end
            set(gca,'FontSize',font_size)
        end
    end
    print('-dpng', [result_path subject '_psychokernel_freq.png']);
    print('-dpdf', [result_path subject '_psychokernel_freq.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% response time
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    for i=1:nSessions
        subplot(floor(sqrt(nSessions)),ceil(nSessions/floor(sqrt(nSessions))),i)
        hold on
        x=0:0.2:1;
        for j=1:size(x,2)-1
            r_correct(1,j) = mean(response_time{i,1}(evidenceStrength{i,1}>=x(j) & evidenceStrength{i,1}<=x(j+1) & outcomeRecord{i,1}==1));
            r_incorrect(1,j) = mean(response_time{i,1}(evidenceStrength{i,1}>=x(j) & evidenceStrength{i,1}<=x(j+1) & outcomeRecord{i,1}==0));
        end
        plot(r_correct,'o','MarkerFaceColor',[0 0 1],'MarkerEdgeColor','none')
        plot(r_incorrect,'o','MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none')
        %axis([0 10 0 2])
    end
    set(gca,'FontSize',font_size)
    ylabel('Response Time','FontSize',font_size)
    xlabel('Evidence Strength','FontSize',font_size)
    title('Response Time')
    print('-dpng', [result_path subject '_response_time.png']);
    print('-dpdf', [result_path subject '_response_time.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% performance
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize', [3 5])
    set(gcf, 'PaperPosition', [0 0 3 5])
    hold on
    sep=1;
    for i=1:nSessions
        plot(performance{i,1}+1*i,'-','Color',[i/nSessions 0 1-i/nSessions],'linewidth',2)
        plot([1 size(performance{i,1},1)],sep*i*[1 1],'-','Color',0.5*[1 1 1],'linewidth',0.5)
        plot([1 size(performance{i,1},1)],sep*i+1*[1 1],'-','Color',0.5*[1 1 1],'linewidth',0.5)
        plot([1 size(performance{i,1},1)],sep*i+0.5*[1 1],'--','Color',0.5*[1 1 1],'linewidth',0.5)

        plot(valid{i,1}+1*i,'-','Color',0.3*[1 1 1],'linewidth',1)
        text(size(performance{i,1},1)+1,sep*i+0.5,num2str(n_difficulties(i,1)),'FontSize',12)
    end
    set(gca,'FontSize',font_size)
    xlabel('Trials','FontSize',font_size)
    ylabel('% Performance','FontSize',font_size)
    title('Performance')
    print('-dpng', [result_path subject '_performance_trace.png']);
    print('-dpdf', [result_path subject '_performance_trace.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% mean performance
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',figure_size)
    set(gcf, 'PaperPosition', [0 0 figure_size])
    hold on
    h1=plot(mean_performance,'Linewidth',1.5);
    plot(mean_performance,'s');
    h2=plot(mean_performance(n_difficulties==1),'-','Linewidth',1.5);
    legend([h1 h2],'psycho','easy','Location','Northwest')
    legend('boxoff')
    set(gca,'FontSize',font_size)
    xlabel('Session','FontSize',font_size)
    ylabel('% Mean performance','FontSize',font_size)
    title('Mean Performance')
    print('-dpng', [result_path subject '_mean_performance_trace.png']);
    print('-dpdf', [result_path subject '_mean_performance_trace.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


    %% mean valid
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',figure_size)
    set(gcf, 'PaperPosition', [0 0 figure_size])
    hold on
    h1=plot(mean_valid,'Linewidth',1.5);
    plot(mean_valid,'s');
    h2=plot(mean_valid(n_difficulties==1),'-','Linewidth',1.5);
    legend([h1 h2],'psycho','easy','Location','Northwest')
    legend('boxoff')
    axis([1 nSessions 0 1])
    set(gca,'FontSize',font_size)
    xlabel('Session','FontSize',font_size)
    ylabel('% Mean valid','FontSize',font_size)
    title('Mean Valid')
    print('-dpng', [result_path subject '_mean_valid_trace.png']);
    print('-dpdf', [result_path subject '_mean_valid_trace.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
   
end