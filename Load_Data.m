addpath(genpath('../'))
clear
close all

%% Load Data
% Load NI Data
session_name = 'myRun0615sync_g0';
NIFileName=fullfile(session_name, sprintf('%s_t0.nidq', session_name));
[NI_META, AIN, DCode_NI] = load_NI_data(NIFileName);

% Load ML Data
% trial_ML = mlread('240615_JianJian_PV_OE.bhv2');
% save Trial_ML.mat trial_ML
load Trial_ML.mat

ImecFileName=fullfile(session_name,sprintf('%s_imec0',session_name), sprintf('%s_t0.imec0.lf',session_name));
[IMEC_META, DCode_IMEC] = load_IMEC_data(ImecFileName);

% Do Sync between Devices
SyncLine = examine_and_fix_sync(DCode_NI, DCode_IMEC);
%% check for alignment between ML and NI
onset_times = 0;
offset_times = 0;
onset_times_by_trial_ML = zeros([1, length(trial_ML)]);
for tt = 1:length(trial_ML)
    onset_times_by_trial_ML(tt) = sum(trial_ML(tt).BehavioralCodes.CodeNumbers==64);
    onset_times = onset_times + onset_times_by_trial_ML(tt);
    offset_times = offset_times + sum(trial_ML(tt).BehavioralCodes.CodeNumbers==32);
end
fprintf('MonkeyLogic Has\n%d trials \n%d onset \n%d offset \n', length(trial_ML), onset_times, offset_times)

LOCS = find(DCode_NI.CodeVal==2);
onset_times_by_trial_SGLX = zeros([1, length(LOCS)]);
for tt = 1:length(LOCS)
    LOC1=LOCS(tt);
    if(tt==length(LOCS))
        LOC2=length(DCode_NI.CodeLoc);
    else
        LOC2=LOCS(tt+1);
    end
    all_code_this_trial = DCode_NI.CodeVal(LOC1:LOC2);
    onset_times_by_trial_SGLX(tt) = sum(all_code_this_trial==64);
end
figure;subplot(1,5,1)
scatter(onset_times_by_trial_SGLX,onset_times_by_trial_ML)
xlabel('onset times SGLX'); ylabel('onset times ML')
if(max(onset_times_by_trial_ML-onset_times_by_trial_SGLX)>0)
    warning('Inconsistant Trial Number')
end
title(sprintf('MaxErr=%d',max(onset_times_by_trial_ML-onset_times_by_trial_SGLX)))

%% check for dataset
dataset_pool = {};
for trial_idx = 1:length(trial_ML)
    dataset_pool{trial_idx}=trial_ML(trial_idx).UserVars.DatasetName;
end
dataset_pool = unique(dataset_pool);

%% check for eye
eye_thres = 0.6;
valid_eye = 0;
onset_marker = 0;
trial_valid_idx = zeros([1,onset_times]);
dataset_valid_idx = zeros([1,onset_times]);
for trial_idx = 1:length(trial_ML)
    trial_data = trial_ML(trial_idx);
    onset_duration = trial_data.VariableChanges.onset_time;
    beh_code = trial_data.BehavioralCodes.CodeNumbers;
    beh_time = trial_data.BehavioralCodes.CodeTimes;
    
    onset_beh_location = find(beh_code==64);
    onset_times_this_trial = length(onset_beh_location);
    img_idx_now = trial_data.UserVars.Current_Image_Train(1:onset_times_this_trial);
    
    dataset_idx = find(strcmp(trial_ML(trial_idx).UserVars.DatasetName, dataset_pool));
    for onset_idx = 1:onset_times_this_trial
        onset_marker = onset_marker + 1;
        onset_start_to_end = (beh_time(onset_beh_location(onset_idx)):beh_time(onset_beh_location(onset_idx))+onset_duration)./trial_data.AnalogData.SampleInterval;
        onset_start_to_end = floor(onset_start_to_end);
        eye_data = trial_data.AnalogData.Eye(onset_start_to_end,:);
        eye_dist = sqrt(eye_data(:,1).^2+eye_data(:,2).^2);
        eye_ratio = sum(eye_dist<trial_data.VariableChanges.fixation_window)./(onset_duration+1);
        if(eye_ratio>eye_thres)
            valid_eye = valid_eye + 1;
            trial_valid_idx(onset_marker) = img_idx_now(onset_idx);
            dataset_valid_idx(onset_marker) = dataset_idx;
        end
    end
end

%% Look Up For Real Onset Time
before_onset_measure = 30;
after_onset_measure = 75;
after_onset_stats = 150;

onset_LOC = find(DCode_NI.CodeVal==64);
onset_times = length(onset_LOC);
po_dis = zeros([onset_times, 1+before_onset_measure+after_onset_stats]);
onset_time_ms = zeros([1, onset_times]);
for tt = 1:onset_times
    onset_time_ms(tt) = floor(DCode_NI.CodeTime(onset_LOC(tt)));
    po_dis(tt,:) = AIN(onset_time_ms(tt)-before_onset_measure:onset_time_ms(tt)+after_onset_stats);
end

subplot(1,5,2)
shadedErrorBar((1:size(po_dis,2))-before_onset_measure,mean(po_dis),std(po_dis))
hold on
baseline = mean(mean(po_dis(:,1:before_onset_measure)));
hignline = mean(mean(po_dis(:,before_onset_measure+after_onset_measure:before_onset_measure+100)));
thres = 0.5*baseline + 0.5*hignline;
yline(thres)
xlabel('time from event');title('Before time calibration')


onset_latency = zeros([1, size(po_dis,1)]);
for tt = 1:size(po_dis,1)
    onset_latency(tt) = find(po_dis(tt,:)>thres,1)-before_onset_measure;
    onset_time_ms(tt) = onset_time_ms(tt) + onset_latency(tt);
end
subplot(1,5,5); hist(onset_latency,20);
xlabel('Latency ms')
xline(min(onset_latency),'LineWidth',2); xline(max(onset_latency),'LineWidth',2)

subplot(1,5,3)
po_dis = zeros([onset_times, 1+before_onset_measure+after_onset_stats]);
for tt = 1:onset_times
    po_dis(tt,:) = AIN(onset_time_ms(tt)-before_onset_measure:onset_time_ms(tt)+after_onset_stats);
end
shadedErrorBar((1:size(po_dis,2))-before_onset_measure,mean(po_dis),std(po_dis))
xlabel('time from event'); title('After time calibration')

subplot(1,5,4)
po_dis = zeros([onset_times, 1+before_onset_measure+after_onset_stats]);
for tt = 1:onset_times
    if(dataset_valid_idx(tt))
        po_dis(tt,:) = AIN(onset_time_ms(tt)-before_onset_measure:onset_time_ms(tt)+after_onset_stats);
    end
end
po_dis(~dataset_valid_idx,:)=[];
shadedErrorBar((1:size(po_dis,2))-before_onset_measure,mean(po_dis),std(po_dis))
xlabel('time from event'); title('Exclude Non-Look Trial')

save Prep_data.mat trial_valid_idx dataset_valid_idx onset_time_ms NI_META AIN DCode_NI IMEC_META DCode_IMEC SyncLine
saveas(gcf,'Prep_sync_ni_ml')

%% Parsing about dataset idx
% Transform about Data
figure
for dataset_idx = 1:length(dataset_pool)
    nexttile
    dataset_tsv = readtable(dataset_pool{dataset_idx}, 'FileType', 'text', 'Delimiter', '\t');
    img_idx = find(dataset_valid_idx==dataset_idx);
    valid_onset = trial_valid_idx(img_idx);
    onset_t = [];
    img_size = size(dataset_tsv,1);
    for img = 1:img_size
        onset_t(img) = sum(valid_onset==img);
    end
    plot(1:img_size,onset_t)
    lines = strsplit(dataset_pool{dataset_idx}, '\');
    title(lines{end})
    xlim([1,img_size])
    ylim([0, max(onset_t)+1])
end
nexttile
scatter(1:length(dataset_valid_idx),dataset_valid_idx)
xlabel('onset idx')
title('which dataset')
saveas(gcf,'Prep_img_size')