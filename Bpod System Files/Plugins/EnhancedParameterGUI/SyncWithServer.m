function SyncWithServer(source,callbackdata)
%SYNCWITHSERVER Summary of this function goes here
%   Detailed explanation goes here

global BpodSystem

serverfolder = '/media/windowsshare/Data/';
datapath = BpodSystem.DataPath;
localdatapath = datapath(strfind(datapath,'Data')+5:end);
serverpath = [serverfolder localdatapath];

subjectfolder = [serverfolder BpodSystem.GUIData.SubjectName '/'];
if ~exist([serverfolder BpodSystem.GUIData.SubjectName])
    mkdir([serverfolder BpodSystem.GUIData.SubjectName])
end

protocolfolder = [subjectfolder BpodSystem.GUIData.ProtocolName '/'];
if ~exist([subjectfolder BpodSystem.GUIData.ProtocolName])
    mkdir([subjectfolder BpodSystem.GUIData.ProtocolName])
    mkdir([subjectfolder BpodSystem.GUIData.ProtocolName '/Session Data'])
end

current_data = datapath(strfind(datapath,'Session Data/')+13:end);
existing_data = dir([protocolfolder '/Session Data']);

already_exists=0;
for x = 1:length(existing_data)
    if x > 2
        if strfind(existing_data(x).name, current_data)
            already_exists=1;
        end
    end
end

save_file=1;
if already_exists
    choice = questdlg('A file with that name already exists in server. Would you like to overwrite?', ...
	'Sync with Server', 'Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            save_file = 1;
        case 'No'
            save_file = 2;
    end
end

if save_file
    SessionData = BpodSystem.Data;
    save(serverpath, 'SessionData', '-v6');
end

end
