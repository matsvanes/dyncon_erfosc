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

if ~exist('dodics_gamma', 'var'), dodics_gamma = false; end
if ~exist('dodics_alpha', 'var'), dodics_alpha = false; end
if ~exist('dofreq', 'var'),       dofreq = false;       end
if ~exist('docomp', 'var'),       docomp = false;       end
if ~exist('getdata', 'var'),      getdata = false;      end
if ~exist('dofreq_short', 'var'), dofreq_short = false; end
if ~exist('dofreq_short_alpha', 'var'), dofreq_short_alpha = false; end
if ~exist('docorrelation', 'var'), docorrelation = false; end
if ~exist('docorrelation_alpha', 'var'), docorrelation_alpha = false; end
if ~exist('dolcmv_parc', 'var'),  dolcmv_parc = false; end
if ~exist('dolcmv_norm', 'var'),  dolcmv_norm = false; end
if ~exist('dosplitpow_lcmv', 'var'), dosplitpow_lcmv = false; end
if ~exist('doPlanar', 'var'), doPlanar = false; end
if ~exist('doglm', 'var'), doglm = false; end
if ~exist('dosplitpow_source', 'var'), dosplitpow_source = false; end


if dodics_gamma, dofreq  = true; end
if dodics_alpha, dofreq  = true; end
if dofreq,       getdata = true; end
if docomp,       getdata = true; end
if dofreq_short, getdata = true; end
if dofreq_short_alpha, getdata = true; end
if dolcmv_parc,  getdata = true; end
if dolcmv_norm,  getdata = true; end
if dosplitpow_lcmv, getdata = true; end
if doglm,     getdata = true; end
if dosplitpow_source, getdata = true; end

% this chunk creates 2 data structures [-0.75 0.5]
if getdata
    if ~exist('undocomp','var')
        undocomp = false;
    end
    [p,f,e]       = fileparts(subject.dataset);
    basedir       = strrep(p, 'raw', 'processed');
    filename_data = fullfile(basedir, 'cleandata.mat');
    load(filename_data);
    
    if undocomp
        filename_comp = fullfile(basedir, 'icaComp.mat');
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
    [data_onset, data_shift] = erfosc_getdata(dataClean, comp);
    clear dataClean;
end

% this chunk does a dss decomposition on the onset-aligned data, and
% applies the topographies to the shift-aligned data
if docomp
    [comp_onset, comp_shift, comp_shift2] = erfosc_dss_onset(data_onset, data_shift);
    
    savedir = '/home/language/jansch/erfosc';
    save(fullfile(savedir, sprintf('sub-%03d_comp', subj)), 'comp_onset', 'comp_shift', 'comp_shift2');
end

% this chunk does spectral decomposition
if dofreq_short
    %     erfosc_comppeaks; % this script has the latency peaks of the handpicked components
    erfosc_lcmvpeaks;
    latency = peaks(subj,1).*[1 1] - 0.02 - [0.15 1./600];
    foi     = subject.gammapeak(end).*[1 1];
    smo     = max(10, diff(subject.gammaband(end,:))./2);
    
    [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
    
    if ~exist('savefreq', 'var')
        savefreq = false;
    end
    if savefreq
        savedir = '/project/3011085.02/scripts/erfosc/analysis_JM_data';%'/home/language/jansch/erfosc';
        save(fullfile(savedir, sprintf('sub-%03d_freqshort', subj)), 'freq_shift', 'P', 'latency');
    end
end

% this chunk does spectral decomposition
if dofreq_short_alpha
    latency = [-0.4 -1./600];
    foi     = [10 10];
    smo     = 2.5;
    
    [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
    
    if ~exist('savefreq', 'var')
        savefreq = false;
    end
    if savefreq
        savedir = '/home/language/jansch/erfosc';
        save(fullfile(savedir, sprintf('sub-%03d_freqshort_alpha', subj)), 'freq_shift', 'P', 'latency');
    end
end

% this chunk does spectral decomposition
if dofreq
    
    if ~exist('latency', 'var')
        latency = [-inf 0-1./data_onset.fsample];
    end
    if dodics_alpha
        foi = [10 10]; smo = 2;
        [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject, foi, smo);
    else
        [freq_onset, freq_shift, P] = erfosc_freq(data_onset, data_shift, latency, subject);
    end
    
    if ~exist('savefreq', 'var')
        savefreq = false;
    end
    if savefreq
        %         savedir = '/home/language/jansch/erfosc';
        savedir = '/project/3011085.02/scripts/erfosc/analysis_JM_data';
        save(fullfile(savedir, sprintf('sub-%03d_freq', subj)), 'freq_shift', 'P', 'latency');
    end
    
end

% this chunk does source reconstruction
if dodics_gamma
    load(fullfile(subject.mridir,'preproc','headmodel.mat'));
    load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
    [source_onset, source_shift, Tval, F] = erfosc_dics_gamma(freq_onset, freq_shift, headmodel, sourcemodel);
    source_onset = rmfield(source_onset, 'cfg');
    source_shift = rmfield(source_shift, 'cfg');
    
    savedir = '/home/language/jansch/erfosc';
    save(fullfile(savedir, sprintf('sub-%03d_source', subj)), 'source_onset', 'source_shift', 'Tval', 'F');
end

if dodics_alpha
    load(fullfile(subject.mridir,'preproc','headmodel.mat'));
    load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
    [source_onset, source_shift, Tval, F] = erfosc_dics_alpha(freq_onset, freq_shift, headmodel, sourcemodel);
    source_onset = rmfield(source_onset, 'cfg');
    source_shift = rmfield(source_shift, 'cfg');
    
    savedir = '/home/language/jansch/erfosc';
    save(fullfile(savedir, sprintf('sub-%03d_source_alpha', subj)), 'source_onset', 'source_shift', 'Tval', 'F');
end

if dolcmv_parc
    load(fullfile(subject.mridir,'preproc','headmodel.mat'));
    load(fullfile(subject.mridir,'preproc','sourcemodel2d.mat'));
    [source_parc] = erfosc_lcmv_parc(data_shift, headmodel, sourcemodel);
    
    savedir = '/home/language/jansch/erfosc';
    save(fullfile(savedir, sprintf('sub-%03d_lcmv', subj)), 'source_parc');
end

if dolcmv_norm
    datadir  = '/home/language/jansch/erfosc';
    filename = fullfile(datadir, sprintf('sub-%03d_lcmv', subj));
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
    erfosc_lcmvpeaks
    datadir1 = '/home/language/jansch/erfosc';
    datadir2 = '/project/3011085.02/scripts/erfosc/analysis_JM_data/'
    load(fullfile(datadir1, sprintf('sub-%03d_source',    subj)));
    %     load(fullfile(datadir, sprintf('sub-%03d_comp',      subj)));
    load(fullfile(datadir2, sprintf('sub-%03d_splitpow', subj)), 'datapst')
    load(fullfile(datadir1, sprintf('sub-%03d_lcmv', subj)));
    load(fullfile(datadir2, sprintf('sub-%03d_freqshort', subj)));
    
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
    
    save(fullfile(datadir2, sprintf('sub-%03d_corr', subj)), 'amp', 'pow', 'rho', 'pval', 'erf');
end

if docorrelation_alpha
    %     erfosc_comppeaks;
    erfosc_lcmvpeaks;
    datadir1 = '/home/language/jansch/erfosc';
    datadir2 = '/project/3011085.02/scripts/erfosc/analysis_JM_data/'
    load(fullfile(datadir1, sprintf('sub-%03d_source_alpha',    subj)));
    %     load(fullfile(datadir, sprintf('sub-%03d_comp',            subj)));
    load(fullfile(datadir2, sprintf('sub-%03d_splitpow', subj)), 'datapst')
    load(fullfile(datadir1, sprintf('sub-%03d_lcmv', subj)));
    load(fullfile(datadir1, sprintf('sub-%03d_freqshort_alpha', subj)));
    
    [val1 idx1] = sort(datapst.trialinfo(:,1));
    datapst.trial = datapst.trial(idx1);
    datapst.trialinfo = datapst.trialinfo(idx1,:);
    
    [m, idx] = min(Tval);
    pow      = (abs(F(idx,:)*transpose(freq_shift.fourierspctrm)).^2)*P;
    %pow      = log10(pow);
    
    %     erf      = cellrowselect(comp_shift.trial, comp_id(subj));
    %     erf      = cat(1,erf{:});
    %     erf      = polarity(subj).*ft_preproc_baselinecorrect(erf, 1, 61);
    erf = cat(1, datapst.trial{:});
    
    ix1 = nearest(datapst.time{1}, peaks(subj,1));
    ix2 = nearest(datapst.time{1}, peaks(subj,2));
    signpeak = sign(mean(mean(erf(:,ix1:ix2),2)));
    erf = signpeak.*erf;
    
    %     ix1 = nearest(comp_shift.time{1}, peaks(subj,1));
    %     ix2 = nearest(comp_shift.time{1}, peaks(subj,2));
    amp = mean(erf(:,ix1:ix2), 2);
    
    [rho, pval] = corr(log10(pow(:)), amp(:), 'type', 'spearman');
    
    save(fullfile(datadir2, sprintf('sub-%03d_corr_alpha', subj)), 'amp', 'pow', 'rho', 'pval', 'erf');
end

if dosplitpow_lcmv
    erfosc_lcmvpeaks;
    
    datadir = '/home/language/jansch/erfosc';
    load(fullfile(datadir, sprintf('sub-%03d_lcmv',    subj)));
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
    
    datadir = '/project/3011085.02/scripts/erfosc/analysis_JM_data/';
    if doPlanar
        save(fullfile(datadir, sprintf('sub-%03d_splitpow_plcmb', subj)), 'f1', 'f2', 'datapst','idx');
        save(fullfile(datadir, sprintf('sub-%03d_splitpow_tfr_plcmb', subj)), 'tfr1', 'tfr2');
    else
        save(fullfile(datadir, sprintf('sub-%03d_splitpow', subj)), 'f1', 'f2', 'datapst');
        save(fullfile(datadir, sprintf('sub-%03d_splitpow_tfr', subj)), 'tfr1', 'tfr2');
    end
end
if doglm
    datadir = '/project/3011085.02/scripts/erfosc/analysis_JM_data/';
    load(fullfile(datadir, sprintf('sub-%03d_corr', subj)));
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'pow';
    cfg.pad    = 2;
    cfg.foi    = [2:2:100];
    cfg.tapsmofrq = ones(1,numel(cfg.foi)).*8;
    cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.25;
    cfg.toi    = (-150:6:0)./300;
    cfg.keeptrials = 'yes';
    cfgb                 = [];
    cfgb.method          = 'template';
    cfgb.template        = 'CTF275_neighb.mat';
    cfgb.neighbours      = ft_prepare_neighbours(cfgb, data_shift);
    cfgb.method          = 'sincos';
    data_shift_planar         = ft_megplanar(cfgb, data_shift);
    data_onset_planar =  ft_megplanar(cfgb, data_onset);
    cfgb = [];
    cfgb.method = 'sum'
    tfr_shift = ft_combineplanar(cfgb, ft_freqanalysis(cfg, data_shift_planar));
    cfg.toi = (-450:6:0)./300;
    tfr_onset = ft_combineplanar(cfgb, ft_freqanalysis(cfg, data_onset_planar));
    
    design = [((amp-mean(amp))./std(amp))'; ones(1,length(amp))];
    
    cfg=[];
    cfg.glm.statistic = 'beta';
    cfg.glm.standardise = false;
    
    for freq = 1:length(tfr_onset.freq)
        for ch = 1:length(tfr_onset.label)
            dat = [squeeze(squeeze(tfr_shift.powspctrm(:,ch,freq,:)))]';
            dat = (dat - repmat(mean(dat,2),[1 length(amp)]))./(repmat(std(dat,[],2),[1 length(amp)]));
            
            tmp = statfun_glm(cfg, dat, design);
            betas(freq,ch,:,:) = tmp.stat(:,1);
            
            dat_bl = [squeeze(squeeze(tfr_onset.powspctrm(:,ch,freq,:)))]';
            dat_bl = (dat_bl - repmat(mean(dat_bl,2),[1 length(amp)]))./(repmat(std(dat_bl,[],2),[1 length(amp)]));
            
            tmp_bl = statfun_glm(cfg, dat_bl, design);
            betas_bl(freq,ch,:,:) = tmp_bl.stat(:,1);
        end
    end
    betas_bl = nanmean(betas_bl,3);
    try
        save(fullfile(datadir, sprintf('sub-%03d_glm', subj)), 'betas', 'betas_bl')
    catch
        save(fullfile(datadir, sprintf('sub-%03d_glm', subj)), 'betas', 'betas_bl','-v7.3')
    end
end
if dosplitpow_source
    datadir1 = '/home/language/jansch/erfosc';
    datadir2 = '/project/3011085.02/scripts/erfosc/analysis_JM_data/';
    load(fullfile(datadir2, sprintf('sub-%03d_splitpow_plcmb', subj)), 'datapst'); % take the trial indexes of sorted trials
    
    load(fullfile(datadir1, 'atlas_subparc374_8k.mat'))
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
    [~, order] = ismember(erftrlinfo, tmp1);
    parceldata_shift.trialinfo = parceldata_shift.trialinfo(order, :); % sort parceldata on erf amp (low-high)
    parceldata_shift.trial = parceldata_shift.trial(order);
    
    % TFR
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'pow';
    cfg.pad    = 2;
    cfg.foi    = subject(subj).gammaband(1):2:subject(subj).gammaband(2)
    cfg.tapsmofrq = ones(1,numel(cfg.foi)).*4;
    cfg.t_ftimwin = ones(1,numel(cfg.foi)).*0.25;
    cfg.toi    = (-300:6:150)./300;
    cfg.trials = 1:100;
    tfr_low = ft_freqanalysis(cfg, parceldata_shift);
    cfg.trials = numel(data_shift.trial)-100 + (1:100);
    tfr_high = ft_freqanalysis(cfg, parceldata_shift);
    
    savedir = '/project/3011085.02/scripts/erfosc/analysis_JM_data/';
    save(fullfile(savedir, sprintf('sub-%03d_splitpow_source', subj)), 'parceldata_shift', 'tfr_low', 'tfr_high')
    
end
    

