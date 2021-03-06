% the rationale for the stuff done in this script is as follows:
% subject specific data handling is done outside functions
% algorithmic pipeline steps are performed inside functions

if ~exist('subj', 'var')
  error('a subject needs to be specified');
end
if ~exist('isPilot', 'var')
  fprintf('assuming that a regular subject is requested\n');
  isPilot = false;
end
if isnumeric(subj) && ~isPilot
  erf_osc_datainfo;
  subject = subjects(subj);
elseif isnumeric(subj) && isPilot
  subject = pilotsubjects(subj);
elseif ~isnumeric(subj)
  error('a subject should be identified by means of a scalar number, otherwise the data handling won''t work');
end

if ~exist('dodics_gamma',         'var'), dodics_gamma         = false; end
if ~exist('dodics_lowfreq',       'var'), dodics_lowfreq       = false; end
if ~exist('dofreq',               'var'), dofreq               = false; end
if ~exist('docomp',               'var'), docomp               = false; end
if ~exist('getdata',              'var'), getdata              = false; end
if ~exist('dofreq_short',         'var'), dofreq_short         = false; end
if ~exist('dofreq_short_lowfreq', 'var'), dofreq_short_lowfreq = false; end
if ~exist('docorrelation',        'var'), docorrelation        = false; end
if ~exist('docorrelation_lowfreq', 'var'), docorrelation_lowfreq = false; end
if ~exist('dolcmv_parc',          'var'), dolcmv_parc          = false; end
if ~exist('dolcmv_parc_msmall',   'var'),  dolcmv_parc_msmall  = false; end
if ~exist('dolcmv_norm',          'var'),  dolcmv_norm         = false; end
if ~exist('dolcmv_norm_msmall',   'var'),  dolcmv_norm_msmall  = false; end
if ~exist('dosplitpow_lcmv',      'var'), dosplitpow_lcmv      = false; end
if ~exist('docorrpow_lcmv',       'var'), docorrpow_lcmv       = false; end
if ~exist('doPlanar',             'var'), doPlanar             = false; end
if ~exist('doglm',                'var'), doglm                = false; end
if ~exist('dosplitpow_source',    'var'), dosplitpow_source    = false; end
if ~exist('doparcel_erf',         'var'), doparcel_erf         = false; end
if ~exist('doresplocked',         'var'), doresplocked         = false; end
if ~exist('dobdssp',              'var'), dobdssp              = false; end
if ~exist('docorrpow_lcmv_lowfreq', 'var'), docorrpow_lcmv_lowfreq = false; end
if ~exist('docorr_gamma_rt',      'var'), docorr_gamma_rt      = false; end
if ~exist('dostat_erf_rt',        'var'), dostat_erf_rt        = false; end
if ~exist('dostat_pow_erf',       'var'), dostat_pow_erf       = false; end

if docorr_gamma_rt, dofreq_short = true; end
if doparcel_erf,    dolcmv_parc  = true; end
if dodics_gamma,    dofreq  = true; end
if dodics_lowfreq,  dofreq  = true; end
if dofreq,          getdata = true; end
if docomp,          getdata = true; end
if dofreq_short,    getdata = true; end
if dofreq_short_lowfreq, getdata = true; end
if dolcmv_parc,     getdata = true; end
if dolcmv_parc_msmall, getdata = true; end
if dolcmv_norm,     getdata = true; end
if dosplitpow_lcmv, getdata = true; end
if docorrpow_lcmv,  getdata = true; end
if docorrpow_lcmv_lowfreq, getdata = true; end
if doglm,           getdata = true; dolcmv_parc = true; end
if dosplitpow_source, getdata = true; end
if dobdssp,         getdata = true; end


% this chunk creates 2 data structures [-0.75 0.5]
if getdata
  if ~exist('undocomp','var')
    undocomp = false;
  end
  [p,f,e]       = fileparts(subject.dataset);
  basedir       = strrep(p, 'raw', 'processed');
  filename_data = fullfile(basedir, sprintf('sub-%03d_cleandata.mat', subj));
  load(filename_data);
  
  if undocomp
    filename_comp = fullfile(basedir, sprintf('sub-%03d_icaComp.mat', subj));
    load(filename_comp);
    sel = zeros(0,1);
    if ~isempty(subject.ecgcomp)
      sel = [sel subject.ecgcomp];
    end
    if ~isempty(subject.eyecomp)
      sel = [sel subject.eyecomp];
    end
    comp.topo     = comp.topo(:,sel);
    comp.unmixing = comp.unmixing(sel,:);
  else
    comp = [];
  end
  [data_onset, data_shift, data_resp] = erfosc_getdata(dataClean, comp);
  clear dataClean;
end

% this chunk does a dss decomposition on the onset-aligned data, and
% applies the topographies to the shift-aligned data
if docomp
  [comp_onset, comp_shift, comp_shift2] = erfosc_dss_onset(data_onset, data_shift);
  
  savedir = '/project/3011085.02/analysis/';
  save(fullfile(savedir, 'comp/', sprintf('sub-%03d/sub-%03d_comp', subj,subj)), 'comp_onset', 'comp_shift', 'comp_shift2');
end

% this chunk does spectral decomposition
if dofreq_short
  peakpicking;%MvE
  latency = peaks(subj,1).*[1 1] - 0.02 - [0.20 1./600];%MvE
  
  foi     = subject.gammapeak(end).*[1 1];
  smo     = max(10, diff(subject.gammaband(end,:))./2);
  [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
  if ~exist('savefreq', 'var')
    savefreq = false;
  end
  if savefreq
    savedir = '/project/3011085.02/analysis/freq/';%MvE
    save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_freqshort_mve', subj,subj)), 'freq_shift', 'P', 'latency');
  end
end

% this chunk does spectral decomposition
if dofreq_short_lowfreq
  load(sprintf('/project/3011085.02/analysis/freq/sub-%03d/sub-%03d_pow_low.mat',subj,subj));
  peakpicking;
  latency = peaks(subj,1).*[1 1] - 0.02 - [0.4 1./600];%MvE
  foi = [peakfreq peakfreq];
  smo     = 2.5;
  [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
  if ~exist('savefreq', 'var')
    savefreq = false;
  end
  if savefreq
    savedir = '/project/3011085.02/analysis/freq';
    save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_freqshort_low', subj,subj)), 'freq_shift', 'P', 'latency');
  end
end

% this chunk does spectral decomposition
if dofreq
  
  if ~exist('latency', 'var')
    latency = [-inf 0-1./data_onset.fsample];
  end
  if dodics_lowfreq
    if ~exist('peakfreq', 'var')
      load(sprintf('/project/3011085.02/analysis/freq/sub-%03d/sub-%03d_pow_low.mat',subj,subj));
    end
    foi = [peakfreq peakfreq]; smo = 2;
    latency = [-0.75+1./data_onset.fsample 0-1./data_onset.fsample];
    [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
  else
    [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject);
  end
  
  if ~exist('savefreq', 'var')
    savefreq = false;
  end
  if savefreq
    savedir = '/project/3011085.02/analysis/freq';
    save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_freq', subj,subj)), 'freq_shift', 'P', 'latency');
  end
  
end

% this chunk does source reconstruction
if dodics_gamma
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  [source_onset, source_shift, Tval, F] = erfosc_dics_gamma(freq_onset, freq_shift, headmodel, sourcemodel);
  source_onset = rmfield(source_onset, 'cfg');
  source_shift = rmfield(source_shift, 'cfg');
  
  savedir = '/project/3011085.02/analysis/source';
  save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_source', subj,subj)), 'source_onset', 'source_shift', 'Tval', 'F');
end

if dodics_lowfreq
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  [source_onset, source_shift, Tval, F] = erfosc_dics_alpha(freq_onset, freq_shift, headmodel, sourcemodel);
  source_onset = rmfield(source_onset, 'cfg');
  source_shift = rmfield(source_shift, 'cfg');
  
  savedir = '/project/3011085.02/analysis/source/';
  save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_source_low', subj,subj)), 'source_shift', 'Tval', 'F');
end

if dolcmv_parc
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  load('atlas_subparc374_8k.mat');
  if doresplocked
    [source_parc] = erfosc_lcmv_parc(data_resp, headmodel, sourcemodel, atlas, doresplocked);
  else
    [source_parc] = erfosc_lcmv_parc(data_shift, headmodel, sourcemodel, atlas, doresplocked);
    savedir = '/project/3011085.02/analysis/source';
    save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_lcmv',subj, subj)), 'source_parc');
  end
end

if dolcmv_norm
  datadir  = '/project/3011085.02/analysis/source';
  filename = fullfile(datadir, sprintf('sub-%03d/sub-%03d_lcmv', subj,subj));
  load(filename);
  
  tmpcfg = [];
  tmpcfg.latency = [-0.2 -1./600];
  data_shift = ft_selectdata(tmpcfg, data_shift);
  
  tmpcfg = [];
  tmpcfg.covariance = 'yes';
  tmp = ft_timelockanalysis(tmpcfg, data_shift);
  
  noise = zeros(numel(source_parc.label),1);
  for k = 1:numel(source_parc.label)
    tmpF = source_parc.F{k}(1,:);
    tmpC = sqrt(tmpF*tmp.cov*tmpF');
    noise(k) = tmpC;
  end
  save(filename, 'noise', '-append');
  
end

if dolcmv_parc_msmall
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  load('atlas_MSMAll_8k_subparc.mat');
  [source_parc] = erfosc_lcmv_parc(data_shift, headmodel, sourcemodel, atlas);
  
  savedir = '/project/3011085.02/analysis/source/';
  save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_lcmv_msmall', subj, subj)), 'source_parc');
end

if dolcmv_norm_msmall
  datadir  = '/project/3011085.02/analysis/source/';
  filename = fullfile(datadir, sprintf('sub-%03d/sub-%03d_lcmv_msmall', subj, subj));
  load(filename);
  
  tmpcfg = [];
  tmpcfg.latency = [-0.2 -1./600];
  data_shift = ft_selectdata(tmpcfg, data_shift);
  
  tmpcfg = [];
  tmpcfg.covariance = 'yes';
  tmp = ft_timelockanalysis(tmpcfg, data_shift);
  
  noise = zeros(numel(source_parc.label),1);
  for k = 1:numel(source_parc.label)
    tmpF = source_parc.F{k}(1,:);
    tmpC = sqrt(tmpF*tmp.cov*tmpF');
    noise(k) = tmpC;
  end
  save(filename, 'noise', '-append');
  
end

% this chunk extracts single trial power and amplitude of
if docorrelation
  %     erfosc_comppeaks;
  %     erfosc_lcmvpeaks
  peakpicking;
  datadir = '/project/3011085.02/analysis//'
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_source',  subj,  subj)));
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow', subj, subj)), 'datapst')
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_lcmv', subj, subj)));
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_freqshort', subj, subj)));
  
  [val1 idx1] = sort(datapst.trialinfo(:,1));
  datapst.trial = datapst.trial(idx1);
  datapst.trialinfo = datapst.trialinfo(idx1,:);
  
  [m, idx] = max(Tval);
  pow      = (abs(F(idx,:)*transpose(freq_shift.fourierspctrm)).^2)*P;
  %pow      = log10(pow);
  
  %     erf      = cellrowselect(comp_shift.trial, comp_id(subj));
  %     erf      = cat(1,erf{:});
  %     erf      = polarity(subj).*ft_preproc_baselinecorrect(erf, 391, 451);
  erf = cat(1, datapst.trial{:});
  
  %     ix1 = nearest(comp_shift.time{1}, peaks(subj,1));
  %     ix2 = nearest(comp_shift.time{1}, peaks(subj,2));
  ix1 = nearest(datapst.time{1}, peaks(subj,1));
  ix2 = nearest(datapst.time{1}, peaks(subj,2));
  signpeak = sign(mean(mean(erf(:,ix1:ix2),2)));
  erf = signpeak.*erf;
  amp = mean(erf(:,ix1:ix2), 2);
  
  [rho, pval] = corr(log10(pow(:)), amp(:), 'type', 'spearman');
  
  save(fullfile(datadir, sprintf('corr/sub-%03d/sub-%03d_corr', subj,subj)), 'amp', 'pow', 'rho', 'pval', 'erf');
end

if docorrelation_lowfreq
  erfosc_lcmvpeaks;
  datadir = '/project/3011085.02/analysis/'
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_source_alpha',  subj,  subj)));
  load(fullfile(datadir, 'freq/', sprintf('sub-%03d/sub-%03d_splitpow', subj, subj)), 'datapst')
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_lcmv', subj, subj)));
  load(fullfile(datadir, 'freq/', sprintf('sub-%03d/sub-%03d_freqshort_alpha', subj, subj)));
  
  [val1 idx1] = sort(datapst.trialinfo(:,1));
  datapst.trial = datapst.trial(idx1);
  datapst.trialinfo = datapst.trialinfo(idx1,:);
  
  [m, idx] = min(Tval);
  pow      = (abs(F(idx,:)*transpose(freq_shift.fourierspctrm)).^2)*P;
  
  erf = cat(1, datapst.trial{:});
  
  ix1 = nearest(datapst.time{1}, peaks(subj,1));
  ix2 = nearest(datapst.time{1}, peaks(subj,2));
  signpeak = sign(mean(mean(erf(:,ix1:ix2),2)));
  erf = signpeak.*erf;
  
  
  amp = mean(erf(:,ix1:ix2), 2);
  
  [rho, pval] = corr(log10(pow(:)), amp(:), 'type', 'spearman');
  
  save(fullfile(datadir,'corr/', sprintf('sub-%03d/sub-%03d_corr_alpha', subj, subj)), 'amp', 'pow', 'rho', 'pval', 'erf');
end

if dosplitpow_lcmv
  %     erfosc_lcmvpeaks;
  peakpicking;
  datadir = '/project/3011085.02/analysis/source/';
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_lcmv',  subj,  subj)));
  source_parc.avg = diag(1./noise)*source_parc.avg;
  
  ix1 = nearest(source_parc.time, peaks(subj,1));
  ix2 = nearest(source_parc.time, peaks(subj,2));
  
  tmpcfg = [];
  tmpcfg.latency = [-0.1 0.5-1./600];
  datapst = ft_selectdata(tmpcfg, data_shift);
  tmpcfg.latency = [-0.2 -1./600] + peaks(subj,1) - 0.02; %0.01;
  datapre = ft_selectdata(tmpcfg, data_shift);
  %clear data_shift;
  
  source_parc.avg  = ft_preproc_baselinecorrect(source_parc.avg, 1, 60);
  [maxval, maxidx] = max(abs(mean(source_parc.avg(:,ix1:ix2),2)));
  signpeak         = sign(mean(source_parc.avg(maxidx,ix1:ix2),2));
  fprintf('parcel with max amplitude = %s\n', source_parc.label{maxidx});
  
  plot_alternative_parcel(source_parc.label{maxidx});
  datapst.trial = source_parc.F{maxidx}(1,:)*datapst.trial;
  datapst.label = source_parc.label(maxidx);
  
  tmpcfg = [];
  tmpcfg.demean = 'yes';
  tmpcfg.baselinewindow = [-inf 0];
  datapst = ft_preprocessing(tmpcfg, datapst);
  
  tmp        = cat(1, datapst.trial{:}).*signpeak; % meak peak up-going
  tmp        = ft_preproc_baselinecorrect(tmp, 1, 60);
  [srt, idx] = sort(mean(tmp(:,ix1:ix2),2));
  datapst.trial = datapst.trial(idx);
  datapst.trialinfo = datapst.trialinfo(idx,:);
  datapre.trial = datapre.trial(idx);
  datapre.trialinfo = datapre.trialinfo(idx,:);
  data_shift.trial = data_shift.trial(idx);
  data_shift.trialinfo = data_shift.trialinfo(idx,:);
  
  
  % powerspectrum
  cfg = [];
  cfg.method = 'mtmfft';
  cfg.output = 'pow';
  cfg.tapsmofrq = 10;
  cfg.foilim = [0 120];
  cfg.trials = 1:100;
  cfg.pad = 1;
  
  if doPlanar
    cfgb                 = [];
    cfgb.method          = 'template';
    cfgb.template        = 'CTF275_neighb.mat';
    cfgb.neighbours      = ft_prepare_neighbours(cfgb, datapre);
    cfgb.method          = 'sincos';
    datapre_planar         = ft_megplanar(cfgb, datapre);
    cfgb = [];
    cfgb.method = 'sum';
    f1 = ft_combineplanar(cfgb, ft_freqanalysis(cfg, datapre_planar));
    cfg.trials = numel(datapre.trial)-100 + (1:100);
    f2 = ft_combineplanar(cfgb, ft_freqanalysis(cfg, datapre_planar));
  else
    f1 = ft_freqanalysis(cfg, datapre);
    cfg.trials = numel(datapre.trial)-100 + (1:100);
    f2 = ft_freqanalysis(cfg, datapre);
  end
  
  % TFR
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'pow';
  cfg.pad    = 2;
  cfg.foi    = [2:2:120];
  cfg.tapsmofrq = ones(1,numel(cfg.foi)).*8;
  cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.25;
  cfg.toi    = (-150:6:90)./300;
  cfg.trials = 1:100;
  
  if doPlanar
    cfgb                 = [];
    cfgb.method          = 'template';
    cfgb.template        = 'CTF275_neighb.mat';
    cfgb.neighbours      = ft_prepare_neighbours(cfgb, data_shift);
    cfgb.method          = 'sincos';
    data_shift_planar         = ft_megplanar(cfgb, data_shift);
    cfgb = [];
    cfgb.method = 'sum';
    tfr1 = ft_combineplanar(cfgb, ft_freqanalysis(cfg, data_shift_planar));
    cfg.trials = numel(data_shift.trial)-100 + (1:100);
    tfr2 = ft_combineplanar(cfgb, ft_freqanalysis(cfg, data_shift_planar));
  else
    tfr1 = ft_freqanalysis(cfg, data_shift);
    cfg.trials = numel(data_shift.trial)-100 + (1:100);
    tfr2 = ft_freqanalysis(cfg, data_shift);
  end
  
  datadir = '/project/3011085.02/analysis/freq';
  if doPlanar
    save(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow_plcmb',subj,  subj)), 'f1', 'f2', 'datapst','idx');
    save(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow_tfr_plcmb',subj,  subj)), 'tfr1', 'tfr2');
  else
    save(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow', subj, subj)), 'f1', 'f2', 'datapst');
    save(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow_tfr',subj, subj)), 'tfr1', 'tfr2');
  end
end
if doglm
  load(sprintf('/project/3011085.02/analysis/freq/sub-%03d/sub-%03d_gamma_virtual_channel.mat',subj, subj), 'gammaPow');
  
  if doresplocked
    parceldata_shift = data_resp;
  else
    parceldata_shift = data_shift;
  end
  
  parceldata_shift.label = source_parc.label
  for k=1:length(source_parc.F);
    spatfilter_parcel(k,:) = source_parc.F{k}(1,:);
  end
  parceldata_shift.trial = spatfilter_parcel*parceldata_shift.trial;
  
  cfg=[];
  cfg.lpfilter = 'yes';
  cfg.lpfilttype = 'firws';
  cfg.lpfreq = 30;
  cfg.lpfiltdir = 'onepass-reverse-zerophase';
  cfg.preproc.demean = 'yes';
  if ~doresplocked
    cfg.preproc.baselinewindow = [-0.1 0];
  end
  parceldata_shift = ft_preprocessing(cfg, parceldata_shift);
  
  if doresplocked
    % add nans for short trials
    tend = zeros(numel(parceldata_shift.time),1);
    for k=1:numel(parceldata_shift.time);
      tend(k,1) = parceldata_shift.time{k}(end); % save the last time point for each trial
      parceldata_shift.time{k} = [parceldata_shift.time{k}, parceldata_shift.time{k}(end)+1/parceldata_shift.fsample:1/parceldata_shift.fsample:0.4];
      parceldata_shift.trial{k} = [parceldata_shift.trial{k}, nan(numel(parceldata_shift.label), numel(parceldata_shift.time{k})-size(parceldata_shift.trial{k},2))];
    end
    cfg=[];
    cfg.latency = [-0.5 0.4];
    erfdata = ft_selectdata(cfg, parceldata_shift);
    tlck=rmfield(erfdata,{'trial', 'time', 'trialinfo'});
    tlck.avg = nanmean(cat(3,erfdata.trial{:}),3);
    tlck.dimord = 'chan_time';
    tlck.time = erfdata.time{1};
  else
    cfg=[];
    cfg.latency = [-0.1 0.5];
    erfdata = ft_selectdata(cfg, parceldata_shift);
    
    cfg=[];
    cfg.latency = [-0.1 0];
    tmp = ft_selectdata(cfg, erfdata);
    tmp.trial = cat(2, tmp.trial{:});
    baseline_std = std(tmp.trial, [], 2);
    cfg=[];
    cfg.vartrllength = 2;
    tlck = ft_timelockanalysis(cfg, erfdata);
  end
  
  
  
  erfdata.trial = cat(3,erfdata.trial{:});
  erfdata.trial = permute(erfdata.trial, [3,1,2]);
  erfdata.time = erfdata.time{1};
  
  design = [gammaPow;((data_shift.trialinfo(:,5)-data_shift.trialinfo(:,4))/1200)'; ones(size(gammaPow))];
  cfg=[];
  cfg.glm.statistic = 'beta';
  cfg.glm.standardise = false;
  
  for k=1:length(erfdata.label)
    dat = [squeeze(erfdata.trial(:,k,:))]';
    if doresplocked
      dat = (dat - repmat(nanmean(dat,2),[1 length(erfdata.trialinfo)]));
      dat(isnan(dat))=0;
    else
      dat = (dat - repmat(mean(dat,2),[1 length(erfdata.trialinfo)]));
    end
    tmp = statfun_glm(cfg, dat, design);
    betas_tmp(k,:) = tmp.stat(:,1);
  end
  
  betas        = rmfield(erfdata,{'trial', 'cfg'});
  betas.avg    = betas_tmp;
  betas.time   = erfdata.time;
  betas.dimord = 'chan_time';
  
  savedir = '/project/3011085.02/analysis/';
  if doresplocked
    save(fullfile([savedir, 'GLM/', sprintf('sub-%03d/sub-%03d_glm_parcelresp', subj, subj)]), 'betas', 'tlck','tend');
  else
    save(fullfile([savedir, 'source/', sprintf('sub-%03d/sub-%03d_parcel_blstd', subj, subj)]), 'baseline_std');
    save(fullfile([savedir, 'GLM/', sprintf('sub-%03d/sub-%03d_glm_parcel', subj, subj)]), 'betas', 'tlck');
  end
end
if dosplitpow_source
  datadir = '/project/3011085.02/analysis/freq/';
  load(fullfile(datadir, sprintf('sub-%03d/sub-%03d_splitpow_plcmb', subj, subj)), 'datapst'); % take the trial indexes of sorted trials
  
  load(fullfile(datadir, 'atlas_subparc374_8k.mat'))
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  foi = subject.gammaband;
  [source_parc] = erfosc_lcmv_parc_gamma(data_shift, headmodel, sourcemodel, atlas, foi);
  
  parceldata_shift = data_shift;
  
  parceldata_shift.label = source_parc.label
  for k=1:length(source_parc.F);
    spatfilter_parcel(k,:) = source_parc.F{k}(1,:);
  end
  parceldata_shift.trial = spatfilter_parcel*parceldata_shift.trial;
  
  % sort based on erf amplitude (as in datapst)
  erftrlinfo = datapst.trialinfo(:,1);
  
  parceltrlinfo=parceldata_shift.trialinfo(:,1);
  [~, order] = ismember(erftrlinfo, parceltrlinfo);
  parceldata_shift.trialinfo = parceldata_shift.trialinfo(order, :); % sort parceldata on erf amp (low-high)
  parceldata_shift.trial = parceldata_shift.trial(order);
  
  % TFR
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'pow';
  cfg.pad    = 2;
  cfg.foi    = 20:2:100
  cfg.tapsmofrq = ones(1,numel(cfg.foi)).*8;
  cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.25;
  cfg.toi    = (-300:6:150)./300;
  cfg.trials = 1:100;
  tfr_high_1 = ft_freqanalysis(cfg, parceldata_shift); % low ERF amp
  cfg.trials = numel(data_shift.trial)-100 + (1:100);
  tfr_high_2 = ft_freqanalysis(cfg, parceldata_shift); % high ERF amp
  
  cfg = [];
  cfg.method = 'mtmconvol';
  cfg.output = 'pow';
  cfg.pad    = 2;
  cfg.foi    = 2:2:30
  cfg.taper  = 'hanning';
  cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.25;
  cfg.toi    = (-300:6:150)./300;
  cfg.trials = 1:100;
  tfr_low_1 = ft_freqanalysis(cfg, parceldata_shift); % low ERF amp
  cfg.trials = numel(data_shift.trial)-100 + (1:100);
  tfr_low_2 = ft_freqanalysis(cfg, parceldata_shift); % high ERF amp
  
  savedir = '/project/3011085.02/analysis/source/';
  save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_splitpow_source', subj, subj)), 'tfr_low_1','tfr_low_2','tfr_high_1', 'tfr_high_2')
end

if doparcel_erf
  parceldata_shift = data_shift;
  
  parceldata_shift.label = source_parc.label;
  for k=1:length(source_parc.F);
    spatfilter_parcel(k,:) = source_parc.F{k}(1,:);
  end
  parceldata_shift.trial = spatfilter_parcel*parceldata_shift.trial;
  
  [~, idx] = sort(parceldata_shift.trialinfo(:,6)-parceldata_shift.trialinfo(:,5), 'ascend');
  parceldata_shift.trial = parceldata_shift.trial(idx);
  parceldata_shift.trialinfo = parceldata_shift.trialinfo(idx);
  
  savedir = '/project/3011085.02/analysis/erf/';
  save(fullfile(savedir, sprintf('sub-%03d/sub-%03d_erfparc', subj, subj)), 'parceldata_shift');
  
end


if docorrpow_lcmv
  peakpicking;
  
  datadir = '/project/3011085.02/analysis/';
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_lcmv',    subj, subj)));
  source_parc.avg = diag(1./noise)*source_parc.avg;
  
  ix1 = nearest(source_parc.time, peaks(subj,1));
  ix2 = nearest(source_parc.time, peaks(subj,2));
  
  tmpcfg = [];
  tmpcfg.latency = [-0.1 0.5-1./600];
  datapst = ft_selectdata(tmpcfg, data_shift);
  tmpcfg.latency = [-0.2 -1./600] + peaks(subj,1) - 0.02;
  datapre = ft_selectdata(tmpcfg, data_shift);
  
  source_parc.avg  = ft_preproc_baselinecorrect(source_parc.avg, 1, 60);
  [maxval, maxidx] = max(abs(mean(source_parc.avg(:,ix1:ix2),2)));
  signpeak         = sign(mean(source_parc.avg(maxidx,ix1:ix2),2));
  fprintf('parcel with max amplitude = %s\n', source_parc.label{maxidx});
  
  for k = 1:numel(source_parc.label)
    F(k,:) = source_parc.F{k}(1,:);
  end
  datapst.trial = F*datapst.trial;
  datapst.label = source_parc.label;
  
  tmpcfg = [];
  tmpcfg.demean = 'yes';
  tmpcfg.baselinewindow = [-inf 0];
  tmpcfg.lpfilter = 'yes';
  tmpcfg.lpfreq = 30;
  tmpcfg.lpfilttype = 'firws';
  tmpcfg.lpfiltdir = 'onepass-reverse-zerophase'
  datapst = ft_preprocessing(tmpcfg, datapst);
  
  tmpcfg = [];
  tmpcfg.latency = peaks(subj,:);%JM
  tmpcfg.avgovertime = 'yes';
  datapeak = ft_selectdata(tmpcfg,datapst);
  
  X = cat(2,datapeak.trial{:});
  Xpow = abs(mean(X,2));
  signswap = diag(sign(mean(X,2)));
  X = signswap*X; % let the amplitude be on average positive
  X = standardise(X,2);
  
  tmpcfg = [];
  tlckpst = ft_timelockanalysis(tmpcfg, datapst);
  tlckpst.avg = signswap*tlckpst.avg;
  
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_source',   subj, subj)));
  if ~exist('freq_shift')
    load(fullfile(datadir, 'freq/', sprintf('sub-%03d/sub-%03d_freqshort',  subj,  subj)));
  end
  [m, idx] = max(Tval);
  pow      = (abs(F(idx,:)*transpose(freq_shift.fourierspctrm)).^2)*P;
  pow      = standardise(log10(pow(:)));
  
  rho = corr(X', pow, 'type', 'spearman'); %MvE
  
  
  tmp = load(sprintf('/project/3011085.02/processed/sub-%03d/ses-meg01/sub-%03d_eyedata.mat', subj, subj));
  % get gamma-ERF correlation, accounting for pupil diameter, without confounding eye position.
  cfg=[];
  cfg.vartrllength = 2;
  cfg.keeptrials = 'yes';
  eye = ft_timelockanalysis(cfg,tmp.data_shift);
  cfg=[];
  cfg.toilim = [-0.2 -1./600] + peaks(subj,1) - 0.02;
  pupild = erfosc_regress_eye(ft_redefinetrial(cfg, eye), {'UADC007'}, {'visAngleX', 'visAngleY'});
  cfg=[];
  cfg.avgovertime = 'yes';
  pupild = ft_selectdata(cfg, pupild);
  pupild = standardise(pupild.trial);
  partialrho1 = partialcorr(X', pow, pupild, 'type', 'spearman');
  
  % get correlation gamma-ERF, accounting for eye position, without confound pupil diameter
  idx = match_str(eye.label, {'visAngleX', 'visAngleY'});
  eye.trial(:,end+1,:) = (eye.trial(:,idx(1),:).^2 + eye.trial(:,idx(2),:).^2).^0.5;
  eye.label{end+1} = 'distance';
  cfg=[];
  cfg.toilim = [-0.2 -1./600] + peaks(subj,1) - 0.02;
  eyepos = erfosc_regress_eye(ft_redefinetrial(cfg, eye), {'distance'}, {'UADC007'});
  cfg=[];
  cfg.avgovertime = 'yes';
  distance = ft_selectdata(cfg, eyepos);
  distance = standardise(distance.trial);
  partialrho2 = partialcorr(X', pow, distance, 'type', 'spearman');
  
  % get correlation gamma-ERF, accounting for eye position and pupil
  % diameter (both not confounded by the other)
  partialrho3 = partialcorr(X', pow, [distance, pupild], 'type', 'spearman');
  
  load atlas_subparc374_8k
  exclude_label = match_str(atlas.parcellationlabel, {'L_???_01', 'L_MEDIAL.WALL_01', 'R_???_01', 'R_MEDIAL.WALL_01'}); %MvE
  
  source = [];
  source.brainordinate = atlas;
  source.label         = atlas.parcellationlabel;
  source.rho           = zeros(374,1);
  source.partialrho    = zeros(374,1);
  source.pow           = zeros(374,1);
  source.dimord        = 'chan';
  
  indx = 1:374;
  indx(exclude_label) = [];
  source.rho(indx)    = rho;
  source.partialrho(indx,1) = partialrho1;
  source.partialrho(indx,2) = partialrho2;
  source.partialrho(indx,3) = partialrho3;
  source.pow(indx)    = Xpow(:);
  
  datadir = '/project/3011085.02/analysis/corr/';
  save(fullfile(datadir, sprintf('sub-%03d/sub-%03d_corrpowlcmv_gamma',subj,  subj)), 'source', 'pow', 'X', 'tlckpst')%, 'pupild', 'distance');
end

if dobdssp
  load(fullfile(subject.mridir,'preproc','headmodel.mat'));
  load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
  load('atlas_subparc374_8k.mat');
  
  cfg         = [];
  cfg.latency = [-0.75 1-1./data_onset.fsample];
  data_onset  = ft_selectdata(cfg, data_onset);
  
  
  if ~isfield(sourcemodel, 'leadfield')
    cfg           = [];
    cfg.headmodel = ft_convert_units(headmodel, 'm');
    cfg.grid      = ft_convert_units(sourcemodel, 'm');
    cfg.grad      = ft_convert_units(data_onset.grad, 'm');
    cfg.channel   = data_onset.label;
    cfg.singleshell.batchsize = 2000;
    sourcemodel   = ft_prepare_leadfield(cfg);
  end
  
  indx = match_str(atlas.parcellationlabel,{'R_19_B05_07'});%;'R_18_B05_02';'R_18_B05_03';'R_18_B05_04'});
  p_indx = ismember(atlas.parcellation,indx);
  
  s = sourcemodel;
  outside = find(~p_indx);
  for k = outside(:)'
    s.leadfield{k} = [];
  end
  s.inside = p_indx;
  
  cfg = [];
  cfg.grid = s;
  cfg.dssp.n_space = min(sum(p_indx),50);
  cfg.dssp.n_intersect = 0.7;
  cfg.dssp.n_in = cfg.dssp.n_space;
  cfg.dssp.n_out = 100;
  data19 = ft_denoise_dssp(cfg, data_onset);
  
  indx = match_str(atlas.parcellationlabel,atlas.parcellationlabel(contains(atlas.parcellationlabel,'R_17')));%;'R_18_B05_02';'R_18_B05_03';'R_18_B05_04'});
  p_indx = ismember(atlas.parcellation,indx);
  
  s = sourcemodel;
  outside = find(~p_indx);
  for k = outside(:)'
    s.leadfield{k} = [];
  end
  s.inside = p_indx;
  
  cfg = [];
  cfg.grid = s;
  cfg.dssp.n_space = 'interactive';%min(sum(p_indx),50);
  cfg.dssp.n_intersect = 'interactive';%0.7;
  cfg.dssp.n_in = 'interactive';%cfg.dssp.n_space;
  cfg.dssp.n_out = 'interactive';%100;
  data17 = ft_denoise_dssp(cfg, data_onset);
  
  cfg = [];
  cfg.vartrllength = 2;
  cfg.preproc.demean = 'yes';
  cfg.preproc.baselinewindow = [-0.1 0];
  cfg.covariance = 'yes';
  cfg.removemean = 'yes';
  tlck   = ft_timelockanalysis(cfg, data_onset);
  tlck19 = ft_timelockanalysis(cfg, data19);
  tlck17 = ft_timelockanalysis(cfg, data17);
  
  s = sourcemodel;
  cfg = [];
  cfg.method = 'lcmv';
  cfg.headmodel = headmodel;
  cfg.grid      = s;
  cfg.keepleadfield = 'yes';
  cfg.lcmv.keepfilter = 'yes';
  cfg.lcmv.fixedori   = 'yes';
  cfg.lcmv.lambda     = '20%';
  %cfg.lcmv.weightnorm = 'unitnoisegain'; % this confuses me in terms of the
  %unit-gain inspection when keeping the leadfields: it's also just a scaling
  cfg.lcmv.keepleadfield = 'yes';
  cfg.lcmv.keepori = 'yes';
  source   = ft_sourceanalysis(cfg, tlck);
  source19 = ft_sourceanalysis(cfg, tlck19);
  source17 = ft_sourceanalysis(cfg, tlck17);
  
  cfg = [];
  cfg.latency = [-0.5 -1./600];
  datapre = ft_selectdata(cfg, data_onset);
  data19pre = ft_selectdata(cfg, data19);
  data17pre = ft_selectdata(cfg, data17);
  cfg.latency = [0.25 0.75-1./600];
  datapst = ft_selectdata(cfg ,data_onset);
  data19pst = ft_selectdata(cfg, data19);
  data17pst = ft_selectdata(cfg, data17);
  
  F   = zeros(size(source.pos,1), numel(data19.label));
  F19 = zeros(size(source19.pos,1), numel(data19.label));
  F17 = zeros(size(source17.pos,1), numel(data19.label));
  F(source.inside,:) = cat(1, source.avg.filter{:});
  F19(source19.inside,:) = cat(1, source19.avg.filter{:});
  F17(source17.inside,:) = cat(1, source17.avg.filter{:});
  
  cfg = [];
  cfg.method = 'mtmfft';
  %cfg.foilim = [30 100];
  %cfg.pad    = 8;
  %cfg.tapsmofrq = 16;
  cfg.taper = 'hanning';
  cfg.output = 'pow';
  fpre = ft_freqanalysis(cfg, datapre);
  fpst = ft_freqanalysis(cfg, datapst);
  f19pre = ft_freqanalysis(cfg, data19pre);
  f19pst = ft_freqanalysis(cfg, data19pst);
  f17pre = ft_freqanalysis(cfg, data17pre);
  f17pst = ft_freqanalysis(cfg, data17pst);
  
  f1pre = ft_checkdata(f1pre,'cmbrepresentation','fullfast');
  f1pst = ft_checkdata(f1pst,'cmbrepresentation','fullfast');
  f2pre = ft_checkdata(f2pre,'cmbrepresentation','fullfast');
  f2pst = ft_checkdata(f2pst,'cmbrepresentation','fullfast');
  
  for k = 1:numel(f1pre.freq)
    pow1pre(:,k) = abs(sum(F1.*(F1*f1pre.crsspctrm(:,:,k)),2));
    pow1pst(:,k) = abs(sum(F1.*(F1*f1pst.crsspctrm(:,:,k)),2));
    pow2pre(:,k) = abs(sum(F2.*(F2*f2pre.crsspctrm(:,:,k)),2));
    pow2pst(:,k) = abs(sum(F2.*(F2*f2pst.crsspctrm(:,:,k)),2));
  end
  
end


if docorrpow_lcmv_lowfreq
  peakpicking;
  
  datadir = '/project/3011085.02/analysis/';
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_lcmv',  subj,  subj)));
  source_parc.avg = diag(1./noise)*source_parc.avg;
  
  ix1 = nearest(source_parc.time, peaks(subj,1));
  ix2 = nearest(source_parc.time, peaks(subj,2));
  
  tmpcfg = [];
  tmpcfg.latency = [-0.1 0.5-1./600];
  datapst = ft_selectdata(tmpcfg, data_shift);
  tmpcfg.latency = [-0.2 -1./600] + peaks(subj,1) - 0.02;
  
  source_parc.avg  = ft_preproc_baselinecorrect(source_parc.avg, 1, 60);
  [maxval, maxidx] = max(abs(mean(source_parc.avg(:,ix1:ix2),2)));
  signpeak         = sign(mean(source_parc.avg(maxidx,ix1:ix2),2));
  fprintf('parcel with max amplitude = %s\n', source_parc.label{maxidx});
  
  for k = 1:numel(source_parc.label)
    F(k,:) = source_parc.F{k}(1,:);
  end
  datapst.trial = F*datapst.trial;
  datapst.label = source_parc.label;
  
  tmpcfg = [];
  tmpcfg.demean = 'yes';
  tmpcfg.baselinewindow = [-inf 0];
  tmpcfg.lpfilter = 'yes';
  tmpcfg.lpfreq = 30;
  tmpcfg.lpfilttype = 'firws';
  tmpcfg.lpfiltdir = 'onepass-reverse-zerophase';
  datapst = ft_preprocessing(tmpcfg, datapst);
  
  tmpcfg = [];
  tmpcfg.latency = peaks(subj,:);
  tmpcfg.avgovertime = 'yes';
  datapeak = ft_selectdata(tmpcfg,datapst);
  
  X = cat(2,datapeak.trial{:});
  Xpow = abs(mean(X,2));
  signswap = diag(sign(mean(X,2)));
  X = signswap*X; % let the amplitude be on average positive
  X = standardise(X,2);
  
  tmpcfg = [];
  tlckpst = ft_timelockanalysis(tmpcfg, datapst);
  tlckpst.avg = signswap*tlckpst.avg;
  
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_source_low',  subj,  subj)));
  load(fullfile(datadir, 'freq/', sprintf('sub-%03d/sub-%03d_freqshort_low', subj, subj)));
  [m, idx] = min(Tval);
  pow      = (abs(F(idx,:)*transpose(freq_shift.fourierspctrm)).^2)*P;
  pow      = standardise(log10(pow(:)));
  
  rho = corr(X', pow, 'type', 'spearman'); %MvE
  load atlas_subparc374_8k
  exclude_label = match_str(atlas.parcellationlabel, {'L_???_01', 'L_MEDIAL.WALL_01', 'R_???_01', 'R_MEDIAL.WALL_01'}); %MvE
  
  source = [];
  source.brainordinate = atlas;
  source.label         = atlas.parcellationlabel;
  source.rho           = zeros(374,1);
  source.pow           = zeros(374,1);
  source.dimord        = 'chan';
  
  indx = 1:374;
  indx(exclude_label) = [];
  source.rho(indx)    = rho;
  source.pow(indx)    = Xpow(:);
  
  
  datadir = '/project/3011085.02/analysis/';
  save(fullfile(datadir, 'corr/', sprintf('sub-%03d/sub-%03d_corrpowlcmv_low', subj, subj)), 'source', 'pow', 'X', 'tlckpst');
end
if docorr_gamma_rt
  load(sprintf('/project/3011085.02/analysis/behavior/sub-%03d/sub-%03d_rt.mat',subj, subj));
  datadir = '/project/3011085.02/analysis/';
  load(fullfile(datadir, 'source/', sprintf('sub-%03d/sub-%03d_source',  subj,  subj)));
  
  pow      = (abs(F*transpose(freq_shift.fourierspctrm)).^2)*P;
  pow      = log10(pow);
  s = std(pow, [], 2);
  u = mean(pow, 2);
  pow = (pow-repmat(u, [1 size(pow,2)]))./repmat(s, [1 size(pow,2)]);
  
  rho = corr(rt, pow', 'type', 'spearman'); %MvE
  rho=rho';
  
  filename = sprintf('/project/3011085.02/analysis/corr/sub-%03d/sub-%03d_corr_3Dgamma_rt.mat', subj, subj);
  save(filename, 'rho')
end
if dostat_pow_erf
  if ~exist('GA'); GA = input('send out single subject analyses (0), or continue to group analysis (1)?'); end
  if ~exist('whichFreq'); whichFreq = input('gamma (1), lowfreq (2)?'); end
  if ~GA
    sel = setdiff(1:33,10);
    for k = sel(:)'
      if whichFreq==1
        qsubfeval('erfosc_execute_pipeline','erfosc_script_jm',k,{'docorrpow_lcmv',1}, {'dofreq_short', 1},{'savefreq', 0},'memreq',8*1024^3,'timreq',59*60,'batchid',sprintf('subj%03d',k));
      elseif whichFreq==2
        qsubfeval('erfosc_execute_pipeline','erfosc_script_jm',k,{'docorrpow_lcmv_lowfreq',1}, {'dofreq_short_lowfreq', 1},{'savefreq', 0},'memreq',8*1024^3,'timreq',59*60,'batchid',sprintf('subj%03d',k));
      end
    end
  else
    load atlas_subparc374_8k.mat
    
    datadir = '/project/3011085.02/analysis/';
    erf_osc_datainfo;
    k=1;
    for subj = allsubs
      if whichFreq==1
        filename = fullfile([datadir, 'corr/', sprintf('sub-%03d/sub-%03d_corrpowlcmv_gamma.mat', subj, subj)]);
      elseif whichFreq==2
        filename = fullfile([datadir, 'corr/', sprintf('sub-%03d/sub-%03d_corrpowlcmv_low.mat', subj, subj)]);
      end
      load(filename,'source');
      if k==1
        S=source;
        S.rho = source.rho;
        if whichFreq==1
          S_pupild.rho = source.partialrho(:,1);
          S_xy.rho = source.partialrho(:,2);
          S_eye.rho = source.partialrho(:,3);
        end
      else
        S.rho(:,k)=source.rho;
        if whichFreq==1
          S_pupild.rho(:,k) = source.partialrho(:,1);
          S_xy.rho(:,k) = source.partialrho(:,2);
          S_eye.rho(:,k) = source.partialrho(:,3);
        end
      end
      k=k+1;
    end
    S.rho = S.rho';
    exclude_label = match_str(atlas.parcellationlabel, {'L_???_01', 'L_MEDIAL.WALL_01', 'R_???_01', 'R_MEDIAL.WALL_01'}); %MvE
    S.rho(:, exclude_label) = nan; %MvE
    S.dimord = 'rpt_chan_freq';
    S.freq = 0;
    
    
    S2 = S;
    S2.rho(:) = 0;
    
    n = 32;
    
    cfgs = [];
    cfgs.method='montecarlo';
    cfgs.design=[ones(1,n) ones(1,n)*2;1:n 1:n];
    cfgs.statistic='ft_statfun_wilcoxon';
    cfgs.numrandomization=10000;
    cfgs.ivar=1;
    cfgs.uvar=2;
    cfgs.parameter='rho';
    cfgs.correctm='cluster';
    cfgs.clusterthreshold='nonparametric_individual';
    cfgs.connectivity = parcellation2connectivity_midline(atlas);
    cfgs.neighbours = cfgs.connectivity; %MvE
    cfgs.tail = 1;
    cfgs.clustertail = 1;
    cfgs.correcttail = 'prob';
    cfgs.clusteralpha = 0.05;
    cfgs.alpha = 0.05;
    
    stat=ft_freqstatistics(cfgs,S,S2);
    
    if whichFreq==1;
      S_pupild.rho = S_pupild.rho';
      S_xy.rho = S_xy.rho';
      S_eye.rho = s_eye.rho';
      S_pupild.rho(:, exclude_label) = nan;
      S_xy.rho(:, exclude_label) = nan;
      S_xy.rho(:, exclude_label) = nan;
      
      stat_pupild=ft_freqstatistics(cfgs,S_pupild,S2);
      stat_xy=ft_freqstatistics(cfgs,S_xy,S2);
      stat_eye=ft_freqstatistics(cfgs,S_eye,S2);
    end
    
    
    if whichFreq==1;
      filename = '/project/3011085.02/analysis/stat_peakpicking_gamma.mat';
      save(filename, 'stat', 'S', 'S_pupild', 'S_xy', 'stat_eye', 'stat_pupild', 'stat_xy');
    elseif whichFreq==2
      filename = '/project/3011085.02/analysis/stat_peakpicking_lowfreq.mat';
      save(filename, 'stat','S');
    end
  end
end
if dostat_erf_rt
  erf_osc_datainfo;
  load atlas_subparc374_8k
  
  datadir = '/project/3011085.02/analysis/';
  k=1;
  
  d = dir('*corrpowlcmv_peakpicking_gamma.mat');
  
  
  for subj = allsubs
    filename = fullfile([datadir, 'corr/', sprintf('sub-%03d/sub-%03d_corrpowlcmv_peakpicking_gamma.mat', subj, subj)]);
    tmp = load(filename,'X', 'pow');
    X{k}=tmp.X;
    pow{k}=tmp.pow;
    k=k+1;
  end
  k=1;
  for subj=allsubs
    tmp = load(sprintf('/project/3011085.02/analysis/behavior/sub-%03d/sub-%03d_rt.mat', subj,subj));
    rt{k} = tmp.rt;
    k=k+1;
  end
  
  for k=1:32
    rho{k} = corr(X{k}', rt{k}, 'type', 'spearman'); %MvE
  end
  
  exclude_label = match_str(atlas.parcellationlabel, {'L_???_01', 'L_MEDIAL.WALL_01', 'R_???_01', 'R_MEDIAL.WALL_01'}); %MvE
  
  source = [];
  source.brainordinate = atlas;
  source.label         = atlas.parcellationlabel;
  source.freq          = 0;
  source.dimord        = 'rpt_chan_freq';
  source.rho           = zeros(32,374);
  
  indx = 1:374;
  indx(exclude_label) = [];
  source.rho(:,indx) = cat(2,rho{:})';
  source.rho(:,exclude_label) = nan;
  
  
  ref=source;
  ref.rho(:) = 0;
  
  n = 32;
  
  cfgs = [];
  cfgs.method='montecarlo';
  cfgs.design=[ones(1,n) ones(1,n)*2;1:n 1:n];
  cfgs.statistic='ft_statfun_wilcoxon';
  cfgs.numrandomization=10000;
  cfgs.ivar=1;
  cfgs.uvar=2;
  cfgs.parameter='rho';
  cfgs.correctm='cluster';
  cfgs.clusterthreshold='nonparametric_individual';
  cfgs.connectivity = parcellation2connectivity_midline(atlas);
  cfgs.neighbours = cfgs.connectivity; %MvE
  cfgs.correcttail = 'prob';
  cfgs.tail = -1;
  cfgs.clustertail = -1;
  cfgs.alpha = 0.05;
  cfgs.clusteralpha = 0.01;
  
  stat=ft_freqstatistics(cfgs,source, ref);
  
  filename = '/project/3011085.02/analysis/stat_corr_peakpicking_rt.mat';
  save(filename, 'stat', 'source');
end
