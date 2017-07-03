function [psycho] = psychofcn(x,y,side,n_bins)

%PSYCHOFCN Summary of this function goes here
%   Detailed explanation goes here
% x is the stimulus/evidence strengh normalized from 0 to 1
% y is 1 if the trial outcome: 0 is incorrect, 1 is correct, any other value is invalid
% side is the correct side: 1 is left, 2 is right  

    bin_size = 2/(2*n_bins+1); %difficulty goes from -1 to 1

    half_x=0:bin_size:1;
    psycho_x = unique([-half_x half_x]);
    psycho_y = nan(1,2*n_bins+1);
    for s=1:2
        for ibin=1:n_bins

            ntrials = sum(x>half_x(ibin)+bin_size/2 & x<=half_x(ibin+1)+bin_size/2 & side==s & y>=0);
            ntrials_correct = sum(x>half_x(ibin)+bin_size/2 & x<=half_x(ibin+1)+bin_size/2 & side==s & y==1);

            p = binofit(ntrials_correct,ntrials);

            if s==2 % 1 is left, 2 is right
                psycho_y(n_bins+ibin+1) = p;
            else
                psycho_y(n_bins-ibin+1) = 1-p;
            end
        end
    end
    % zero evidence
    ntrials = sum(x<=bin_size/2 & side==2 & y>=0); 
    ntrials_right = sum(x==0 & side==2 & y==1); %2 is right
    [p c] = binofit(ntrials_right,ntrials);
    psycho_y(n_bins+1) = p;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    psycho.x = psycho_x;
    psycho.y = psycho_y;
    psycho.n_bins = n_bins;
end