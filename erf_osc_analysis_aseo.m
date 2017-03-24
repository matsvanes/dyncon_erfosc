function erf_osc_analysis_aseo(subj, isPilot, existWindow)
% This function selects time windows for which the specific ERF peaks and
% it selects the channels for which the amplitude is highest. Based on
% these parameters, the ASEO algorithm (Xu et al, 2009) models the
% event-related response and ongoing activity seperately.
% 1. find optimal window for the peaks by selecting highest amplitude
% channels in occipital/parietal sensors.
% 2. find specific timewindows for every peak using globalmeanfield
% close all
if nargin<1
    subj = 1;
end
if isempty(subj)
    subj = 1;
end
if nargin<2
    isPilot = false;
end
if isempty(isPilot);
    isPilot = false;
end
if nargin<3
    existWindow = false;
end
if isempty(existWindow);
    existWindow = false;
end



%% initiate diary
workSpace = whos;
diaryname = sprintf('/project/3011085.02/scripts/erfosc/tmpDiary_%s.txt', datestr(now, 'dd.mm.yyyy_HH:MM:SS'));
diary(diaryname) % save command window output
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
erf_osc_datainfo;
if isPilot
    data = load(sprintf('/project/3011085.02/processed/pilot-%03d/ses-meg01/cleandata.mat', subj), 'dataClean');
    load(sprintf('/project/3011085.02/results/erf/pilot-%03d/timelock.mat', subj));
    load(pilotsubjects(subj).logfile);% load log file
else
    data = load(sprintf('/project/3011085.02/processed/sub-%03d/ses-meg01/cleandata.mat', subj), 'dataClean');
    load(sprintf('/project/3011085.02/results/erf/sub-%03d/timelock.mat', subj));
    load(subjects(subj).logfile);% load log file
end
data = data.dataClean;
fs = data.fsample;

% select only shift trials, with valid response
idxM        = find(data.trialinfo(:,5)>0 & data.trialinfo(:,6)>0);
cfg         = [];
cfg.trials  = idxM;
cfg.channel = 'MEG';
data        = ft_selectdata(cfg, data);

% redifine zero point to shift onset
cfg         = [];
cfg.offset  = -(data.trialinfo(:,5)-data.trialinfo(:,4));
dataShift   = ft_redefinetrial(cfg, data);

cfg         = [];
cfg.latency = [-0.05+1/fs 0.75];
dataShift   = ft_selectdata(cfg, dataShift);

cfg=[];
cfg.demean = 'yes';
cfg.baselinewindow = [-0.05+1/fs 0];
dataShift = ft_preprocessing(cfg, dataShift);

%% baseline correction and z-scoring
cfg=[];
cfg.baseline = [-0.05+1/fs 0];
cfg.baselinetype = 'abs';
tl = ft_timelockbaseline(cfg, tlShift);

t1 = nearest(tl.time, (-0.5+1/fs));
t2 = nearest(tl.time, 0);
s = std(tl.avg(:,t1:t2), [], 2);
m = mean(tl.avg(:, t1:t2), 2);
M = repmat(m, [1, size(tl.avg,2)]);

% two z scoring options: x/s or (x-m)/s?
tlZscore=tl;
tlZscore.avg=diag(1./s)*(tl.avg-M);
gmf = ft_globalmeanfield([], tlZscore);

%% Select time window
% take a first guess at the time window, select channels with highest
% amplitudes in this window. Then base more precise estimation of time
% window these channels

guess = [0.050 0.090; 0.095 0.130; 0.135 0.180];
    cfg=[];
    cfg.layout = 'CTF275_helmet.mat';
    tmp = rmfield(tlZscore, 'cfg');
    ft_topoplotER(cfg, tmp);
    if existWindow
        load(sprintf('/project/3011085.02/results/erf/sub-%03d/aseo.mat', subj), 'window', 'windowGuess'); % load ERF
    else
        for iPeak = 1:size(guess,1)
            windowGuess{iPeak} = input('What is the initial estimate of the peak latencies?')
        end
    end
for iPeak=1:size(guess,1)
    
    cfg=[];
    cfg.latency = [windowGuess{iPeak}(iPeak,1) windowGuess{iPeak}(iPeak,2)];
    cfg.channel = {'MRP', 'MLP', 'MZP', 'MZO', 'MLO', 'MRO'};
    critWin_guess = ft_selectdata(cfg, tlZscore);
    
    % take mean of every channel
    avgChan_guess = mean(critWin_guess.avg, 2);
    
    % find 8 channels with max abs amplitude in critical window, then seperate
    % them into negative and positive (pole). Average them accordingly after
    % 'flipping' the negative pole
    selChan_1 = 8;
    [~, maxAbsIdx_guess] = sort(abs(avgChan_guess), 1, 'descend');
    maxAbsIdx_guess = maxAbsIdx_guess(1:selChan_1);
    chanIdxPos_guess = maxAbsIdx_guess(find(avgChan_guess(maxAbsIdx_guess)>0));
    chanIdxNeg_guess = maxAbsIdx_guess(find(avgChan_guess(maxAbsIdx_guess)<0));
    
    cfg=[];
    cfg.channel = critWin_guess.label(chanIdxPos_guess);
    dataPos_guess = ft_selectdata(cfg, tlZscore);
    cfg.channel = critWin_guess.label(chanIdxNeg_guess);
    dataNeg_guess = ft_selectdata(cfg, tlZscore);
    %
    cfg = [];
    cfg.operation = 'multiply';
    cfg.scalar = -1;
    cfg.parameter = 'avg';
    dataNegFlip_guess = ft_math(cfg, dataNeg_guess);
    
    erfdata_selchan = ft_appenddata([], dataPos_guess, dataNegFlip_guess);
    
    gmf_selchan = ft_globalmeanfield([], erfdata_selchan);
    
    % plot globalmeanfield and z-scores timelock data
    figure; cfgp=[]; cfgp.xlim = [windowGuess{iPeak}(iPeak,1) windowGuess{iPeak}(iPeak,2)]; cfgp.layout = 'CTF275_helmet.mat'; ft_topoplotER(cfgp, tlZscore)
    figure; subplot(2,1,1); plot(gmf_selchan.time, gmf.avg);hold on; plot(gmf_selchan.time, gmf_selchan.avg); title('(X-M)/s'); xlim([-0.05 0.5]);
    subplot(2,1,2); cfg=[]; cfg.xlim = [-0.05 0.5]; ft_singleplotER(cfg, erfdata_selchan); hold on; hline(0);
    if ~existWindow
        window{iPeak} = input('What is the latency window of every individual peak?');
    end
    
    for i=1:size(window{iPeak}, 1)
        lat = mean([window{iPeak}(i,2) window{iPeak}(i,1)]);
        var = max(lat/5, 0.01); % lowest peak jitter is 10 ms
        windowvar{iPeak}(i,:) = [-var var];
    end
    
    %% Select channels
    
    % select critical window
    cfg=[];
    cfg.latency = [window{iPeak}(iPeak,1) window{iPeak}(iPeak,2)];
    cfg.channel = {'MRP', 'MLP', 'MZP', 'MZO', 'MLO', 'MRO'};
    critWin = ft_selectdata(cfg, tlZscore);
    
    % take mean of every channel
    avgChan = mean(critWin.avg, 2);
    nchan = length(critWin.label);
    
    % find 8 channels with max abs amplitude in critical window, then seperate
    % them into negative and positive (pole). Average them accordingly after
    % 'flipping' the negative pole
    selChan = 8;
    [~, maxAbsIdx] = sort(abs(avgChan), 1, 'descend');
    maxAbsIdx = maxAbsIdx(1:selChan);
    chanIdxPos = maxAbsIdx(find(avgChan(maxAbsIdx)>0));
    chanIdxNeg = maxAbsIdx(find(avgChan(maxAbsIdx)<0));
    
    cfg=[];
    cfg.channel = critWin.label(chanIdxPos);
    dataPos = ft_selectdata(cfg, dataShift);
    cfg.channel = critWin.label(chanIdxNeg);
    dataNeg = ft_selectdata(cfg, dataShift);
    %
    cfg = [];
    cfg.operation = 'multiply';
    cfg.scalar = -1;
    cfg.parameter = 'trial';
    dataNegFlip = ft_math(cfg, dataNeg);
    
    erfdata = ft_appenddata([], dataPos, dataNegFlip);
    cfg=[];
    cfg.avgoverchan = 'yes';
    erfdata = ft_selectdata(cfg, erfdata);
    
    cfg=[];
    cfg.xlim = [-0.05 0.5];
    figure; ft_singleplotER(cfg, erfdata);
    
    %% Analysis of Singletrial ERP and Ongoing acivity
    % Seperately model the evoked components and the ongoing activity from
    % a first estimate. Iterate this n times.
%     cfg             =[];
%     cfg.lpfilter    = 'yes';
%     cfg.lpfreq      = 30;
%     cfg.lpfilttype  = 'firws';
%     erfdata         = ft_preprocessing(cfg, erfdata);
    
    cfg                      = [];
    cfg.method               = 'aseo';
    cfg.aseo.noise           = 'white';
    cfg.aseo.waveformInitSet = window{iPeak};
    cfg.aseo.numiteration    = 1;
    cfg.aseo.jitter          = windowvar{iPeak};
    [reconstructed{iPeak}, residual{iPeak}] = ft_singletrialanalysis(cfg, erfdata);
end
% Combine the latency and amplitude parameters from the ASEO applied to the
% specific peaks (with specific timewindow and channel parameters)
for iPeak = 1:size(window,1)
    latency(:, iPeak) = reconstructed{iPeak}.params.latency(:, iPeak);
    amplitude(:, iPeak) = reconstructed{iPeak}.params.amplitude(:, iPeak);
end

%% save
if isPilot
    filename = sprintf('/project/3011085.02/results/erf/pilot-%03d/aseo', subj);
else
    filename = sprintf('/project/3011085.02/results/erf/sub-%03d/aseo', subj);
end
save(fullfile([filename '.mat']), 'erfdata', 'reconstructed', 'residual', 'latency', 'amplitude', 'window', 'windowGuess', 'windowvar')
diary off
movefile(diaryname, fullfile([filename, '.txt']));


end
