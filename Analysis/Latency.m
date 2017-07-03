clear
close all
clc

font_size = 12;
figure_size = [4 3];

time = clock;
date_time = [date '-' num2str(time(4)) '-' num2str(time(5))];
result_path = ['~/../../media/fede/Data/Data-on-Satellite/AAAApostdoc/zador/research/b-pod/Results/latency-' date_time '/'];
mkdir(result_path);

subjectpath = '../Data/';
subject_prefix = 'FT'; protocol = 'ToneCloudsFixedTime';
%subject_prefix = 'RT'; protocol = 'ToneClouds4BPod';


subjects = dir([subjectpath '/' subject_prefix '*']);
subjects={subjects.name}'; %session files ordered by date
n_subjects = size(subjects,1);


latency = cell(1,n_subjects);
for m=1:n_subjects

    subject = subjects{m,:};

    datapath = ['../Data/' subject '/' protocol '/Session Data/'];

    files = dir([datapath '/*.mat']);
    [ignore,idx]=sort([files.datenum]);
    files={files(idx).name}'; %session files ordered by date

    nSessions = size(files,1);
    
    latency{1,m} = cell(1,nSessions);
    
    nTrials = cell(nSessions,1);
    for i=1:nSessions

        try
        load([datapath files{i,:}])
        catch
            disp(['Couldn`t load file: ' files{i,:}])
            break
        end
        
        nTrials{i,1} = size(SessionData.TrialTypes,2);
        
        latency{1,m}{1,i} = nan(1,nTrials{i,1});
        for j=1:nTrials{i,1}
        
            if isfield(SessionData.RawEvents.Trial{1,j}.Events,'BNC1High')...
                && isfield(SessionData.RawEvents.Trial{1,j}.Events,'BNC2High')
                t1 = SessionData.RawEvents.Trial{1,j}.Events.BNC1High; %time when 'play' instruction is sent from arduino
                t2 = SessionData.RawEvents.Trial{1,j}.Events.BNC2High; %time when sound is actually played
                try
                    latency{1,m}{1,i}(1,j) = t2-t1;
                    if latency{1,m}{1,i}(1,j)>0.4
%                        display('')
                    end
                catch ME
%                    display('')
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% latency histogram
figure('Visible','Off')
set(gcf, 'PaperUnits', 'inches')
set(gcf, 'PaperSize',figure_size)
set(gcf, 'PaperPosition',[0 0 figure_size])
bin_width=10;
for m=1:n_subjects
    a{1,m}=cell2mat(latency{1,m});
end
lat=cell2mat(a);
[n x] = hist(lat*1000,1:10:1000);
f=100*n/sum(n);
bar(x,f,'barwidth',0.7,'edgecolor',[1 0.5 0],'facecolor',[0.9 0.4 0],'linewidth',1.5)
set(gca,'FontSize',font_size)
box off
xlabel('Latency (ms)','FontSize',font_size)
ylabel('%','FontSize',font_size)
a=find(f~=0);
axis([0 x(a(end))+100 0 max(f)+10])
xlim =get(gca,'Xlim');
ylim =get(gca,'Ylim');
text(0.75*xlim(2),0.75*ylim(2),['N: ' num2str(sum(n))],'FontSize',font_size)
[v ind] = max(n);
text(x(ind)+20,f(ind),[num2str(x(ind),'%2.2f') ' ms' ],'FontSize',font_size)
title('Latency')
print('-dpng', [result_path 'latency_hist.png']);
print('-dpdf', [result_path 'latency_hist.pdf']);
close
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% latency histogram per session and subject
for m=1:n_subjects
    figure('Visible','Off')
    set(gcf, 'PaperUnits', 'inches')
    set(gcf, 'PaperSize',[10 10])
    set(gcf, 'PaperPosition',[0 0 10 10])
    bin_width=10;
    nSessions = size(latency{1,m},2);
    lat_session = nan(1,nSessions);
    for i=1:nSessions
        lat=latency{1,m}{1,i};
        lat = lat(~isnan(lat));
        if ~isempty(lat)
            lat_session(1,i) = 1;
        else
            lat_session(1,i) = 0;
        end
    end
    n_lat_session= sum(lat_session);
    lat_session_indx = find(lat_session);
    for i=1:n_lat_session
        subplot(floor(sqrt(n_lat_session)),ceil(n_lat_session/floor(sqrt(n_lat_session))),i)
        lat=latency{1,m}{1,lat_session_indx(i)};
        lat = lat(~isnan(lat));
        if ~isempty(lat) %there was measure of latency in the session
            [n x] = hist(lat*1000,1:10:1000);
            f=100*n/sum(n);
            bar(x,f,'barwidth',0.7,'edgecolor',[1 0.5 0],'facecolor',[0.9 0.4 0],'linewidth',1.5)
            set(gca,'FontSize',font_size)
            box off
            xlabel('Latency (ms)','FontSize',font_size)
            ylabel('%','FontSize',font_size)
            a=find(f~=0);
            axis([0 x(a(end))+100 0 max(f)+10])
            xlim =get(gca,'Xlim');
            ylim =get(gca,'Ylim');
            text(0.75*xlim(2),0.75*ylim(2),['N: ' num2str(sum(n))],'FontSize',font_size)
            [v ind] = max(n);
            text(x(ind)+20,f(ind),[num2str(x(ind),'%2.2f') ' ms' ],'FontSize',font_size)
        end
    end
    title('Latency')
    print('-dpng', [result_path subjects{m,1} '_latency_hist.png']);
    print('-dpdf', [result_path subjects{m,1} '_latency_hist.pdf']);
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end