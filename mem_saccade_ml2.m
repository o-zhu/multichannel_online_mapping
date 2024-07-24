%% Memory guided saccade task Monkeylogic 2
editable('fix_window_radius_ms','target_window_radius_ms','radius_ms','reward_dur_ms','time_to_saccade_ms')

%% Variables

wait_for_fix_ms = 5000;
fixation_time_ms = 500;
fix_window_radius_ms = 3;
initial_fix_ms = 150;

fix_hpos_ms = 0;
fix_vpos_ms = 0;

target_time_ms = 300; %target flashes up for this long before delay
time_to_saccade_ms = 500; %has this much time to make saccade to target location % 500
target_fix_time_ms = 150; %has to look at the target location for this long after he saccades to it %150
target_window_radius_ms = 5; %4
delay_time_ms = 1000;

set_iti(900);

inv_train_params=1;%was used to make it easier on inv trials, with bigger target window radius, longer time to saccade, etc...but when fully trained, these parameters are same as for visible condition

eventmarker(14);% memory saccade task
eventmarker(Info.marker);  % eventmarker 120-127 for the 8 mem saccade conditions

radius_ms = 7;   %7;
angle = Info.angle;
new_xpos = radius_ms*cos(angle);
new_ypos = radius_ms*sin(angle);

display_target = 1;

num_rewards_ms = 1;
reward_dur_ms = 173;

if fix_hpos_ms~=0 || fix_vpos_ms~=0
    success = reposition_object(1, fix_hpos_ms, fix_vpos_ms);  %resposition fixation spot
    if ~success
        error('Failed to reposition object number 1.');
    end
end

toggleobject(1,'eventmarker',35); % turn on fix spot

[ontarget, rt] = eyejoytrack('acquirefix',[1],[fix_window_radius_ms], wait_for_fix_ms); %acquire fix, stay w/in fix window

if ~ontarget(1)% doesn't fixate within wait_for_fix
    trialerror(4); %no fixation
    rt=NaN;
    toggleobject(1,'eventmarker',36); % turn off fix spot
    return
end

[ontarget, rt] = eyejoytrack('holdfix',[1],[fix_window_radius_ms], initial_fix_ms); %in case he's on border of fix window,

if ~ontarget(1)
end

[ontarget, rt] = eyejoytrack('holdfix',[1],[fix_window_radius_ms], fixation_time_ms);% maintain fix w/in fix window for duration of fixation_time

if ~ontarget(1) %if break fix
    trialerror(3); %break fixation
    rt=NaN;
    toggleobject(1,'eventmarker',36); % turn off fix spot
    return
end

% if fixates for specified time,

repos = reposition_object(2, new_xpos, new_ypos);  % if target is repositioned, repos=1
toggleobject(2,'eventmarker',25); % turn on target at (new_xpos, new_ypos)

[ontarget, rt] = eyejoytrack('holdfix',1,fix_window_radius_ms, target_time_ms); %maintain fix while target flashes

if ~ontarget(1)
    trialerror(3); %break fixation
    rt=NaN;
    toggleobject(1,'eventmarker',36); %turn off fix spot
    toggleobject(2,'eventmarker',26);  %turn off target
    return
end

toggleobject(2,'eventmarker',26);  %turn off target

% delay period : fix spot on, target off

[ontarget, rt] = eyejoytrack('holdfix',[1],[fix_window_radius_ms],delay_time_ms);

if ~ontarget(1)
    trialerror(3); %break fixation
    rt=NaN;
    toggleobject(1,'eventmarker',36); % turn off fix spot
    return
end

toggleobject(1,'eventmarker',36); % turn off fix spot ->this is cue for monkey to make saccade

visibility = rand(1); %generate a random number between 0 and 1
vis_threshold = 1; %if 1, target invisible after delay
if visibility>=vis_threshold
    display_target=1; %target visible after delay on 70% of trials if vis_treshold=0.3
    user_text('targ_win_rad: %i',target_window_radius_ms);
    user_text('targ_fx_tm: %i',target_fix_time_ms);
    user_text('time_to_sac: %i',time_to_saccade_ms);
    user_text('Visible target');
else
    display_target=0;
    if inv_train_params==1%to make it easier on inv trials during training
        tts = time_to_saccade_ms;%was*2
        tft = target_fix_time_ms;%was/2
        twr = target_window_radius_ms;%was+1
    end
    user_text('targ_win_rad: %i',twr);
    user_text('targ_fx_tm: %i',tft);
    user_text('time_to_sac: %i',tts);
    user_text('Invisible target');
end

if display_target == 1 %monkey sees target after delay. for training
    
    repos = reposition_object(3, new_xpos, new_ypos);
    toggleobject(3,'eventmarker',27);  %turn on target (white square)
    
    [ontarget, rt] = eyejoytrack('acquirefix',[3],[target_window_radius_ms], time_to_saccade_ms);% saccade to target location within time_to_saccade
    
    if ~ontarget(1)
        trialerror(6); %incorrect saccade
        rt=NaN;
        toggleobject (3,'eventmarker',28); %turn off target
        return
    end
    
    [ontarget, rt] = eyejoytrack('holdfix',[3],[target_window_radius_ms], initial_fix_ms); %in case he's on border of fix window,
    
    if ~ontarget(1)
    end
    
    [ontarget, rt] = eyejoytrack('holdfix',[3],[target_window_radius_ms], target_fix_time_ms); %fixate at target location for duration of target_fix_time
    
    if ~ontarget(1)
        trialerror(6);
        re=NaN;
        toggleobject (3,'eventmarker',28); %turn off target
        return
    end
    
    if ontarget ==1 %if monkey makes correct saccade
        toggleobject(3,'eventmarker',28); %turn off target
        trialerror(0); %correct
        goodmonkey(reward_dur_ms,num_rewards_ms,100); %100=pause between multiple rewards
        eventmarker(96); %reward given
        return
    end
    
end

if display_target == 0 %target is on-screen, but invisible. fully memory guided
    repos = reposition_object(4, new_xpos, new_ypos);
    toggleobject(4,'eventmarker',29);  %turn on (invisible) target
    
    [ontarget, rt] = eyejoytrack('acquirefix',[4],[twr], tts);
    
    if ~ontarget(1),
        trialerror(6); %incorrect saccade or no saccade
        rt=NaN;
        toggleobject(4,'eventmarker',30); %turn off target
        return
    end
    
    [ontarget, rt] = eyejoytrack('holdfix',[4],[twr], initial_fix_ms); %in case he's on border of fix window,
    
    if ~ontarget(1)
    end
    
    [ontarget, rt] = eyejoytrack('holdfix',[4],[twr], tft); %fixate at target location for duration of target_fix_time
    
    if ~ontarget(1)
        trialerror(6);
        re=NaN;
        toggleobject (4,'eventmarker',30); %turn off target
        return
    end
    
    if ontarget ==1 %if monkey makes correct saccade
        toggleobject(4,'eventmarker',30); %turn off target
        trialerror(0); %correct
        % goodmonkey(reward_dur_ms,num_rewards_ms,100);
        goodmonkey(reward_dur_ms, 'NumReward', num_rewards_ms, 'PauseTime', 100); %100=pause between multiple rewards
        eventmarker(96); %reward given
        return
    end
    
end


