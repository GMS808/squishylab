function [MSD, tau, tauTrack, indivMSDlist] = Mean_SD_many_single_beads(path, timeint, number_of_frames)

% This program calculates the mean squared displacement for all beads at 
% all possible lag times from 1 to number_of_frames. The result is the sum
% of the x and y MSD.
% Follows "rg_matrix_many_single_beads".
%
% INPUTS
%
% path - the base path for the experiment. Reads in the individual
% beads files and the correspondance matrix with Rg from the 
% "Bead_Tracking\ddposum_files\individual_beads\" subfolder.
% timeint - the (average) delta-t between frames, in seconds
% number_of_frames - maximum lag time to consider (typically number of 
% frames recorded per FOV).
%
% OUTPUTS
%
% Creates a "1pt_msd" subfolder where it outputs
% "MSD_of_#_beads_rgcutoff_#nm.mat" and "MDSx..." and "MSDy..." files.
% (Usually not used)
% MSD - a vector containing the MSD in micrometer squared for each lag time tau
% tau - a vector of each lag time tau, in seconds
%
figure(10) % clear fig10 for individual bead MSDs
clf;
load([path 'Bead_Tracking\ddposum_files\individual_beads\correspondance']);

msdpath = '1pt_msd';
[status, message, messageid] = mkdir([path msdpath]);

tau=timeint:timeint:(number_of_frames-1)*timeint;
tauTrack = zeros(2,length(tau)); % Matrix to keep track of how many MSDs go into the <MSD> for each tau
tauTrack(1,:) = tau;

MSD=zeros(number_of_frames-1,1);
MSDx=zeros(number_of_frames-1,1);
MSDy=zeros(number_of_frames-1,1);
pointtracer=zeros(number_of_frames-1,1); % number of MSDs for each tau
beadcount = 0;
indivBeadMSDs = zeros(number_of_frames-1,length(correspondance(:,1)));
indivMSDlist = {};

for i = 1:length(correspondance(:,1)) % for each bead tracked
    tic
    clear M
    clear Mx
    clear My
    clear SD
    beadcount = beadcount + 1;
    load([path 'Bead_Tracking\ddposum_files\individual_beads\bead_' num2str(i)]);
    lastframe=length(bsec(:,3)); % how many frames is this trajectory
    bsectauX=zeros(number_of_frames-1,1);
    bsectauY=zeros(number_of_frames-1,1);
    bsecx=(bsec(:,1)-bsec(1,1)); % reset initial x position to zero
    bsecy=(bsec(:,2)-bsec(1,2)); % reset initial y position to zero
    indivMSD = bsectauX;
    for delta=1:(lastframe-1) % for each lag time value
        for t=1:(lastframe-delta) % for each lag time of delta
            bsectauX(delta)=bsectauX(delta)+(bsecx(t)-bsecx(t+delta))^2;
            bsectauY(delta)=bsectauY(delta)+(bsecy(t)-bsecy(t+delta))^2;
            pointtracer(delta) = pointtracer(delta)+1; 
            tauTrack(2,delta) = tauTrack(2,delta) + 1; % Keep track of each MSD
        end
        indivMSD(delta) = (bsectauX(delta) + bsectauY(delta))/t;
        indivBeadMSDs(delta,i)=indivMSD(delta);
    end
        individual_MSDs(tau,indivMSD,'b');
        indivMSDlist{i} = indivMSD;
        MSDx=MSDx+bsectauX;
        MSDy=MSDy+bsectauY;
        MSD=MSD+bsectauX+bsectauY;
        xlswrite('IndivBeadMSDs',indivBeadMSDs)
    
    if mod(i,50) == 0
        disp(['Finished computing MSD for bead number ' num2str(i)])
    end
    str = ['Bead #' num2str(i) ' Completed in ' num2str(toc) ' seconds...'];
    disp(str);
    
end


%howmanyPoints=numbeads*(number_of_frames-(1:number_of_frames-1))';

MSD=MSD./pointtracer;
MSDx=MSDx./pointtracer;
MSDy=MSDy./pointtracer;
individual_MSDs(tau,MSD,'r');
% Dropped the rg piece at the end of the filenames because rg data is not
% present
save([path msdpath '\MSD_of_' num2str(beadcount)],'MSD')
save([path msdpath '\MSDx_of_' num2str(beadcount)],'MSDx')
save([path msdpath '\MSDy_of_' num2str(beadcount)],'MSDy')


