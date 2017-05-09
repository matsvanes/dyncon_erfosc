function erf_osc_analysis_gamma_pow(subj, isPilot)
% This function makes an estimate of gamma power increase active-baseline
% in order to exclude participants that do not show a clear gamma peak

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

%% initiate diary
workSpace = whos;
diaryname = tempname;
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
else
    data = load(sprintf('/project/3011085.02/processed/sub-%03d/ses-meg01/cleandata.mat', subj), 'dataClean');
end
data=data.dataClean;
fs = data.fsample;

% select only shift trials, with valid response
idxM = find(data.trialinfo(:,5)>0 & data.trialinfo(:,6)>0);
nTrials = length(idxM);

cfg        = [];
cfg.trials = idxM;
cfg.channel = 'MEG';
data       = ft_selectdata(cfg, data);

for iTrl=1:size(data.trial,2)
    blonset(iTrl,1) = data.time{iTrl}(1);
end
cfg=[];
% baseline window
% cfg.trl = [data.trialinfo(:,3), data.trialinfo(:,4) data.trialinfo(:,3)-data.trialinfo(:,4)];
% the first column represents the start of the baseline period. It's sample
% number is inaccurate w.r.t. the time axis in the data (possibly because
% of previous use of ft_selectdata?). This results in NaNs in the data. 
% Thus, don't use the samplenumber provided by trialinfo, but calculate on 
% the spot based on time axis.
cfg.trl = [data.trialinfo(:,4)+blonset*fs, data.trialinfo(:,4)];
cfg.trl = [cfg.trl, cfg.trl(:,1)-cfg.trl(:,2)];
dataBl = ft_redefinetrial(cfg, data);

cfg=[];
% post erf period till stimulus reversal
cfg.trl = [data.trialinfo(:,4)+0.4*fs data.trialinfo(:,5) 0.4*fs*ones(nTrials,1)];
dataAct = ft_redefinetrial(cfg, data);

cfg         = [];
cfg.length  = 0.5; % 0.5 second windows
cfg.overlap = 0.5; % half overlap
bl = ft_redefinetrial(cfg, dataBl); % PROBLEM!!
% bl.trial contains NaNs. in ft_freqanalysis, this results in the whole
% array becoming NaN. specifically in ft_preproc_polyremoval of
% ft_specest_mtmfft
act = ft_redefinetrial(cfg, dataAct);


%% gamma power
cfg             = [];
cfg.method      = 'mtmfft';
cfg.output      = 'pow';
cfg.taper       = 'hanning';
cfg.foilim      = [2 100];
cfg.keeptrials  = 'no'; % average baseline over trials
cfg.channel     = {'MLO', 'MZO', 'MRO'};
powBl        = ft_freqanalysis(cfg, bl);
powAct       = ft_freqanalysis(cfg, act);


%% save
if isPilot
    filename = sprintf('/project/3011085.02/results/freq/pilot-%03d/gamma_pow', subj);
else
    filename = sprintf('/project/3011085.02/results/freq/sub-%03d/gamma_pow', subj);
end
save(fullfile([filename '.mat']), 'gamPowBl', 'gamPowAct');
diary off
movefile(diaryname, fullfile([filename '.txt']));


end

