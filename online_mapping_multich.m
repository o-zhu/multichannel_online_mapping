function online_mapping_multich(ch_list)

%% Online mapping for MGS multichannel, parallel execution of spikerates_mgs

close all

% Detect if there is existing parallel pool
s = matlabpool('size');

if s==0
    matlabpool(4)
end

%% Run mapping script in parallel

channel_list = ch_list;
num_channels = size(channel_list,2);

% Run mapping scripts in parallel
parfor workerindex = 1:num_channels
    
    spikerates_mgs(channel_list(workerindex))

end


end