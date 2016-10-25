function erf_osc_analysis_corr(subj)

if nargin<1
    subj = 4;
end
if isempty(subj)
    subj = 4;
end

%% initiate diary
workSpace = whos;
diary('tmpDiary') % save command window output
fname = mfilename('fullpath')
datetime

fid = fopen(fullfile([fname '.m']));
tline = fgets(fid); % returns first line of fid
while ischar(tline) % at the end of the script tline=-1
    disp(tline) % display tline
    tline = fgets(fid); % returns the next line of fid
end
fclose(fid);

for i = 1:numel(workSpace) % list all workspace variables
    workSpace(i).name % list the variable name
    printstruct(eval(workSpace(i).name)) % show its value(s)
end

%% load data
% load gamma peak freq
load(sprintf('/home/electromag/matves/Results/ERF_oscillation/freq/%02d/gamma_peak_%d.mat', subj, subj), 'peakFreq');

% load gamma power
load(sprintf('/home/electromag/matves/Results/ERF_oscillation/freq/%02d/gamma_pow_%d.mat', subj, subj));
gammaPow = gamPow.powspctrm;

% load gamma phase
load(sprintf('/home/electromag/matves/Results/ERF_oscillation/freq/%02d/gamma_angle_%d', subj, subj));

% load ERF
load(sprintf('/home/electromag/matves/Results/ERF_oscillation/erf/%02d/dss_ASEO_%d.mat', subj, subj), 'q1');


%% gamma pow - ERF components
peakIdx = find(gamPow.freq==peakFreq);
[rAmp pAmp] = corr(gammaPow(:,peakIdx), q1(1).params.amplitude, 'type', 'pearson')
[rLat pLat] = corr(gammaPow(:,peakIdx), q1(1).params.latency, 'type', 'pearson')

for iFreq = 1:length(gamPow.freq)
[rA(iFreq,:), pA(iFreq,:)] = corr(gammaPow(:,iFreq), q1(1).params.amplitude, 'type', 'pearson');
[rL(iFreq,:), pL(iFreq,:)] = corr(gammaPow(:,iFreq), q1(1).params.latency, 'type', 'pearson');
end

%% gamma phase - ERF components
gamAngle = rad2deg(gamAngle);
bins = 0:60:360;
angleBin = zeros(nTrials,1);
for iTrl = 1:nTrials
angleBin(iTrl) = bins(nearest(bins, gamAngle(iTrl)));
end
angleBin(angleBin==0) = 360;

idx60 = find(angleBin==60);
idx120 = find(angleBin==120);
idx180 = find(angleBin==180);
idx240 = find(angleBin==240);
idx300 = find(angleBin==300);
idx360 = find(angleBin==360);

gam60 = mean(gammaPow(idx60,1));
gam120 = mean(gammaPow(idx120,1));
gam180 = mean(gammaPow(idx180,1));
gam240 = mean(gammaPow(idx240,1));
gam300 = mean(gammaPow(idx300,1));
gam360 = mean(gammaPow(idx360,1));

gam = [gam60, gam120, gam180, gam240, gam300, gam360];

plot(60:60:360, gam, '.')


%% save
% filename = sprintf('/home/electromag/matves/Results/ERF_oscillation/freq/%02d/gamma_pow_%d', subj, subj);
% save(fullfile([filename '.mat']), 'gammaPow');
% diary off
% movefile('tmpDiary', fullfile([filename '.txt']));
end
