function [LFP_META, LFP_resampled] = load_LFP_data(NIFileName)
    
    LF_file = dir([NIFileName,'\*lf.bin']);
    LF_META_file = dir([NIFileName,'\*lf.meta']);
    LFP_META=load_meta(fullfile(NIFileName,LF_META_file.name));
    nFileBytes = LFP_META.fileSizeBytes;
    nChan = LFP_META.nSavedChans;
    nFileSamp = nFileBytes / (2 * nChan);
    fprintf('Load LFP DATA\nn_channels: %d, n_file_samples: %d\n', nChan, nFileSamp);
    fprintf('Recording Last %04d seconds %03d mins\n', floor(nFileSamp./LFP_META.imSampRate), floor(nFileSamp./LFP_META.imSampRate/60));
    m = memmapfile(fullfile(NIFileName, LF_file.name), 'Format', {'int16', [nChan, nFileSamp], 'x'},'Writable', false);
    NI_rawData = m.Data.x;

    fI2V = LFP_META.imAiRangeMax/32768;
    LFP_IN=double(NI_rawData(1:end-1,:))*fI2V;
    % Convert Data Into MS
    % ReSample
    [p, q] = rat(1000 / LFP_META.imSampRate);
    example_channel = resample(LFP_IN(1,:), p, q);
    LFP_resampled = repmat(example_channel, [384,1]);
    for cc = 1:size(LFP_IN,1)
        LFP_resampled(cc,:) = resample(LFP_IN(cc,:), p, q);
    end
end

