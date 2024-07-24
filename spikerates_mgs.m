function spikerates_mgs(ch)

ext = '.fig';
channel = ch;

binSize = 10;
domain = -650:binSize:2500;
span = 15;
plotNums = [6 3 2 1 4 7 8 9];

client = PL_InitClient(0);
pars = PL_GetPars(client);
tick = pars(2)/1000;
%Timestap tick is in usec, convert to msec.
PL_TrialStatus(client,1,0);
%Wait until Plexon is running and collecting data.

n=zeros(1,8);
fullscreen = get(0,'ScreenSize');
h = figure('Position',[100 100 fullscreen(3)/2.5 fullscreen(4)/2]);
figure(h);
totalSpikeRates = zeros(length(domain),8);
meanSpikeRates = zeros(length(domain),8);
meanRewTime = zeros(8);
errors = 0;
while true,
    drawnow;
    ch = get(gcf,'CurrentCharacter');
    if ch == 'q',
        break;
    end
    PL_TrialDefine(client, -14, -18, 0, 0, 0, 0, channel, channel, 0);
% PL_TrialDefine(client, -65298, -65289, 0, 0, 0, 0, channel, channel, 0);
    %Define a trial to start with eventmarker 103 and end with eventmarker
    %18.
    
    [rf tsf ssf asf lts] = PL_TrialStatus(client,2,10000);
    %Wait for trial to begin.
    
    [rf tsf ssf asf lts] = PL_TrialStatus(client,3,5000);
    %Wait for trial to end.
    if lts~= 1,
        fprintf('No trial!\n');
        errors = errors+1;
        continue;
    end
    
    [en et] = PL_TrialEvents(client,0,0);
    eventTimes = et(:,1);
    eventNumbers = -et(:,2);
% %     %%%%%%%%%modified for the new system since i have a systematic error
% %     eventNumbers = -et(:,2)-65280;
    eventTimes = eventTimes .* tick;
    reward = eventTimes(eventNumbers==96);
    if isempty(reward)
        %Incorrect trial
        continue;
    end
    [sn st] = PL_TrialSpikes(client,0,0);
    spikeTimes = st(:,1);
    unitOne = find(st(:,3)==1);
    spikeTimes = spikeTimes(unitOne);
    spikeTimes = spikeTimes .* tick;
    if isempty(spikeTimes),
        fprintf('No spikes found!\n');
        errors = errors+1;
        continue;
    end
    
    targetOn = eventTimes(eventNumbers==25);
    endOfDelay = eventTimes(eventNumbers==36) - targetOn;
    targetOff = eventTimes(eventNumbers==26) - targetOn;
    rewTime = eventTimes(eventNumbers==96) - targetOn;
    targetLoc = eventNumbers(eventNumbers>=120 & eventNumbers<=127);
    targetLoc = targetLoc-119;
    if isempty(targetOn),
        fprintf('No target-on eventmarkers found!\n');
        errors = errors+1;
        continue;
    elseif length(targetOn)>1,
        fprintf('Extra target-on eventmarkers found!\n');
        errors = errors+1;
        continue;
    end
    if isempty(targetLoc),
        fprintf('No target location eventmarkers found!\n');
        errors = errors+1;
        continue;
    elseif length(targetLoc)>1,
        fprintf('Extra target location eventmarkers found!\n');
        errors = errors+1;
        continue;
    end
    
%     if errors >= 1,
%         PL_Close(client);
%         error('*** Fifty consecutive anomalous trials ***');
%     end
    
    spikeTimes = spikeTimes - targetOn;
    spikeRatesOrig = histc(spikeTimes,domain);
    spikeRates = spikeRatesOrig/binSize;
    spikeRates = spikeRates*1000;
    spikeRates = smooth(spikeRates,span,'moving');
    if ~all(size(spikeRates)==size(totalSpikeRates(:,targetLoc)))
        spikeRates = spikeRates';
        if ~all(size(spikeRates)==size(totalSpikeRates(:,targetLoc)))
            x = size(spikeRates);
            y = size(totalSpikeRates(:,targetLoc));
            fprintf('Matrix dimension error!\nspikeRates -> [%i x %i], totalSpikeRates(:,targetLoc) -> [%i x %i]\n',x(2),x(1),y(1),y(2));
            continue
%         else
%             fprintf('spikeRates transposed.\n');
        end
    end
    n(targetLoc)=n(targetLoc)+1;
    totalSpikeRates(:,targetLoc) = totalSpikeRates(:,targetLoc) + spikeRates;
    meanSpikeRates(:,targetLoc) = totalSpikeRates(:,targetLoc) / n(targetLoc);
    meanRewTime(targetLoc) = ((n(targetLoc) - 1)*meanRewTime(targetLoc)...
        + rewTime)/n(targetLoc);
    ylim = [0 max(max(meanSpikeRates))];
    xlim = [domain(1) domain(end)];
    title(['Channel number ',num2str(channel)])
    for i=1:8,
        subplot(3,3,plotNums(i));
        cla;
        plot(gca,domain,meanSpikeRates(:,i));
        xlabel('Time (ms)');
        ylabel('Frequency (Hz)');
        line([0 0], ylim, 'Color', [1 0 0], 'LineStyle', '--');
        eodx = [endOfDelay endOfDelay]; % repmat(reshape(endOfDelay,1,2),2,1);
        eody = repmat(reshape(ylim,      2,1),1,2);
        line(eodx, eody, 'Color', [0 1 0], 'LineStyle', '--');
        line([targetOff targetOff], eody, 'Color', [1 0 0], 'LineStyle', '--');
        line([meanRewTime(i) meanRewTime(i)], eody, 'Color', [0 0 1], ...
            'LineStyle', '--');
        set(gca,'ylim',ylim);
        set(gca,'xlim',xlim);
    end
    
    drawnow;
    %errors = 0;
    figname = ['Map_',num2str(channel),ext];
    saveas(h,figname)
end
fprintf('spikerates_ms.m finished.\n');
PL_Close(client);

end