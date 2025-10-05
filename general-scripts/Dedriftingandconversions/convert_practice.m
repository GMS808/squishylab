% Will Hanna
% 13 June 2012
% practice converting res matrix into data for micro-rheology
clc
clear all;
close all;

basepath = 'C:\Users\Will\Summer 2012 Research Lab\5ul_beads_water_experiment\';
fovn = 1;

% run conversion functions
conversions_no_dd(basepath, fovn);
getting_individual_beads(basepath, fovn);

% get MSDs
cd ..\MSD;

timeint = 28.46/725;
number_of_frames = 300; % for speed during testing
rg_cutoff = -1; % not using this for now
maxtime = timeint*number_of_frames/5;
[MSD, tau] = Mean_SD_many_single_beads( basepath, timeint, number_of_frames);
[MSDtau] = making_logarithmically_spaced_msd_vs_tau( MSD, tau, maxtime);

cd ../Dedriftingandconversions;

figure(1)
hold on;
plot(MSDtau(:,1),MSDtau(:,2),'s');
linreg = polyfit(MSDtau(:,1),MSDtau(:,2),1);
plot(MSDtau(:,1), MSDtau(:,1)*linreg(1)+linreg(2),'r');
xlabel('tau [sec]');
ylabel('<delta r^2(tau)> [um^2]');
title('MSD versus tau');
legend('MSD Data','Linear Fit');
axis tight;

cd ../Moduli;
a = 1.01/2; % bead radius
dim = 2; % dimesion
T = 300; % temperature in Kelvin
clip = 0.3; % fraction of G(s) below which G'(w) and G''(w) are meaningless
width = 0.7; % width of Gaussian for polynomial fit
str = ['Slope of MSD versus tau is ' num2str(linreg(1))];
disp(str);

[omega,Gs,Gp,Gpp,dd,dda,] = calc_G(MSDtau(:,1), MSDtau(:,2), a, dim, T, clip, width);

figure(2)
hold on;
plot(omega,Gp,'b');
plot(omega,Gpp,'r');
xlabel('omega [sec^-1]');
ylabel('G'' and G" [Pa]');
title('G'' and G" versus omega');
legend('G''','G''''')
linreg2 = polyfit(omega,Gpp,1);
str = ['Slope of G" versus w is ' num2str(linreg2(1))];
disp(str);

cd ../Dedriftingandconversions;

