function [  ] = individual_MSDs( tau, MSD, c )
%INDIVIDUAL_MSDS Summary of this function goes here
%   Detailed explanation goes here
figure(10)
hold on
xlabel('Lag Time \tau [sec]');
ylabel('<\Delta r^2(\tau)> [\mum^2]');
title('MSD vs. Lag Time \tau');
loglog(tau,MSD,c)


