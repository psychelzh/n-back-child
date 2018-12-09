function [status, exception] = mainOneback(user, part)
% Copyright (C) 2018, Liang Zhang - All Rights Reserved.
% @author      Liang Zhang <psychelzh@outlook.com>
% @description This script is used to display stimuli in fMRI research
%              based on one-back paradigm, using Psychtoolbox as devtool.

% please mannually make sure Psychtoolbox is installed

% ---- set default output ----
status = 0;
exception = [];

try
    % ---- configure screen and window ----
    % setup default level of 2
    PsychDefaultSetup(2);
    % set the start up screen to black
    old_visdb = Screen('Preference', 'VisualDebugLevel', 1);
    % do not skip synchronization test to make sure timing is accurate
    old_sync = Screen('Preference', 'SkipSyncTests', 0);
    % screen selection
    screen_to_display = max(Screen('Screens'));
    % open a window and set its background color as gray
    gray = WhiteIndex(screen_to_display) / 2;
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, gray);
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, 64);
    
    % ---- timing information ----
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    % prestimulus fixation
    fix_secs = 0.5;
    fix_frames = round(fix_secs / ifi);
    % image presentation seconds
    image_secs = 1;
    image_frames = round(image_secs / ifi);
    % interstimulus interval seconds (participants' response is recorded)
    isi_secs = 2;
    isi_frames = round(isi_secs / ifi);
    % make a vector to store the content to show at each frame
    pres_vector = [repelem("fixation", fix_frames), ...
        repelem("image", image_frames), ...
        repelem("isi", isi_frames)];
    n_frames_trial = length(pres_vector);
    
    % ---- keyboard settings ----
    exit_key = KbName('Escape');
    left_key = KbName('LeftArrow');
    right_key = KbName('RightArrow');
    
    % ---- prepare stimuli ----
    N_IMAGES = 10;
    stim_image_ids = 1:N_IMAGES;
    [stim_image_mats, ~, stim_image_alpha] = cellfun(@imread, ...
        fullfile('image', ...
        strcat(cellfun(@(x) sprintf('%02d', x), num2cell(stim_image_ids), 'UniformOutput', false), '.png')), ...
        'UniformOutput', false);
    for stim_i = 1:N_IMAGES
        stim_image_mats{stim_i}(:, :, 4) = stim_image_alpha{stim_i};
    end
    stim_textures = cellfun(@(img) Screen('MakeTexture', window_ptr, img), stim_image_mats);
    
    % ---- prapare sequence ----
    % constants used for sequence generation
    N_TRIALS = 160; % 2 means change and stay each once
    STIM_TYPE_FILLER = "filler";
    % freq of each resp type: "one-back", "two-back", "three-back", "control"
    STIM_TYPE_WEIGHT = [2, 1, 1, 6];
    % set random seed based on current time
    rng('shuffle')
    % note that the images are not presented with equal number of repetitions
    stim_type_trials = N_TRIALS * STIM_TYPE_WEIGHT / sum(STIM_TYPE_WEIGHT);
    % select the places for "one-back"
    while true
        loc_one_back = sort(randperm(N_TRIALS, stim_type_trials(1)));
        if all(diff(loc_one_back) ~= 1)
            break
        end
    end
    % select the places for "two-back", ensure that they are not directly next
    % to "one-back"
    while true
        loc_rem = setdiff(1:N_TRIALS, loc_one_back);
        loc_two_back = sort(loc_rem(randperm(length(loc_rem), stim_type_trials(2))));
        if all(~ismember(loc_two_back, [1, loc_one_back + 1]))
            break
        end
    end
    % select the places for "three-back", ensure that they are not directly next
    % to "two-back"
    while true
        loc_rem = setdiff(1:N_TRIALS, [loc_one_back, loc_two_back]);
        loc_three_back = sort(loc_rem(randperm(length(loc_rem), stim_type_trials(3))));
        if all(~ismember(loc_three_back, [1, 2, loc_two_back + 1]))
            break
        end
    end
    loc_control = setdiff(1:N_TRIALS, [loc_one_back, loc_two_back, loc_three_back]);
    % generate type sequence
    stim_type_seq = strings(N_TRIALS, 1);
    stim_type_seq(loc_one_back) = "one-back";
    stim_type_seq(loc_two_back) = "two-back";
    stim_type_seq(loc_three_back) = "three-back";
    stim_type_seq(loc_control) = "control";
    % generate texture sequence
    stim_img_seq = zeros(N_TRIALS, 1);
    for i_trial = 1:N_TRIALS
        switch stim_type_seq(i_trial)
            case "one-back"
                if i_trial > 1
                    stim_img_seq(i_trial) = stim_img_seq(i_trial - 1);
                else
                    stim_img_seq(i_trial) = stim_image_ids(randperm(N_IMAGES, 1));
                end
            case "two-back"
                % the least possible `i_trial` will be 2.
                if i_trial > 2
                    stim_img_seq(i_trial) = stim_img_seq(i_trial - 2);
                else
                    stim_img_seq(i_trial) = stim_image_ids(randperm(N_IMAGES, 1));
                end
            case "three-back"
                % the least possible `i_trial` will be 3.
                if i_trial > 3
                    stim_img_seq(i_trial) = stim_img_seq(i_trial - 3);
                else
                    image_candidate = stim_image_ids;
                    if stim_type_seq(i_trial - 1) == "one-back"
                        image_candidate = setdiff(stim_image_ids, stim_img_seq(i_trial - 1));
                    end
                    stim_img_seq(i_trial) = sample(image_candidate, 1);
                end
            case "control"
                image_candidate = stim_image_ids;
                if i_trial > 1
                    image_candidate = setdiff(image_candidate, stim_img_seq(i_trial - 1));
                end
                if i_trial > 2
                    image_candidate = setdiff(image_candidate, stim_img_seq(i_trial - 2));
                end
                if i_trial > 3
                    image_candidate = setdiff(image_candidate, stim_img_seq(i_trial - 3));
                end
                stim_img_seq(i_trial) = sample(image_candidate, 1);
        end
    end
    % get the filler texture
    if stim_type_seq(1) == "one-back"
        stim_img_filler = stim_img_seq(1);
    elseif stim_type_seq(2) == "two-back"
        stim_img_filler = stim_img_seq(2);
    elseif stim_type_seq(3) == "three-back"
        stim_img_filler = stim_img_seq(3);
    else
        stim_img_filler = sample(stim_image_ids, 1, stim_img_seq(1:3));
    end
    stim_type_seq_full = vertcat(STIM_TYPE_FILLER, stim_type_seq);
    stim_img_seq_full = vertcat(stim_img_filler, stim_img_seq);
    
    % ----prepare data recording table ----
    rec_vars = {'stim', 'trial_start_time', 'stim_onset_time', 'type', 'cresp', 'resp', 'acc', 'rt'};
    recordings = cell2table( ...
        repmat({nan, nan, nan, strings, strings, strings, -1, 0}, N_TRIALS + 1, 1), ...
        'VariableNames', rec_vars);
    
    % ---- present stimuli ----
    % set priority to the top
    priority_old = Priority(MaxPriority(window_ptr));
    % instruction
    instruction = ['下面我们玩一个游戏', ...
        '\n屏幕上会一个一个地出现小动物', ...
        '\n你需要判断当前这个小动物是不是和前一个一样', ...
        '\n如果一样就按左键，不一样就按右键'];
    DrawFormattedText(window_ptr, double(instruction), 'center', 'center', [0, 0, 1]);
    Screen('Flip', window_ptr);
    KbStrokeWait; % TODO: change it to 'Enter' key only
    start_time = GetSecs;
    % trial by trial stimuli presentation
    for i_trial = 1:N_TRIALS + 1 % there is one filler trial
        early_exit = false;
        % presentation loop
        resp_made = false;
        frame_to_draw = 0;
        trial_start_time = 0;
        stim_onset_time = 0;
        while ~resp_made
            frame_to_draw = frame_to_draw + 1;
            if frame_to_draw > n_frames_trial
                break
            end
            % draw the corresponding content according to the vectors
            draw_what = pres_vector(frame_to_draw);
            switch draw_what
                case "fixation"
                    DrawFormattedText(window_ptr, '+', 'center', 'center', WhiteIndex(window_ptr));
                case "image"
                    Screen('DrawTexture', window_ptr, stim_textures(stim_img_seq_full(i_trial)));
                case "isi"
                    Screen('FillRect', window_ptr, gray);
            end
            if frame_to_draw == 1
                vbl = Screen('Flip', window_ptr);
                trial_start_time = vbl - start_time;
            else
                vbl = Screen('Flip', window_ptr, vbl + 0.5 * ifi);
                if draw_what == "image" && stim_onset_time == 0
                    stim_onset_time = vbl - start_time;
                end
            end
            % check response
            [~, resp_time, resp_code] = KbCheck(-1);
            % if pressing exit key ('Esc' key), exit the program early
            % might be disabled in release version
            if resp_code(exit_key)
                early_exit = true;
                break
            end
            if draw_what ~= "fixation" && stim_type_seq_full(i_trial) ~= "filler"
                if resp_code(left_key) || resp_code(right_key)
                    resp_made = true;
                    resp_rt = resp_time - stim_onset_time - start_time;
                end
                if resp_code(left_key)
                    resp = "Left";
                    if stim_type_seq_full(i_trial) == "one-back"
                        resp_acc = 1;
                    else
                        resp_acc = 0;
                    end
                end
                if resp_code(right_key)
                    resp = "Right";
                    if stim_type_seq_full(i_trial) ~= "one-back"
                        resp_acc = 1;
                    else
                        resp_acc = 0;
                    end
                end
            end
        end
        % if no response is made, store acc as -1 and rt as 0
        if ~resp_made
            resp = "";
            resp_acc = -1;
            resp_rt = 0;
        end
        % recording current response data
        recordings.stim(i_trial) = stim_img_seq_full(i_trial);
        recordings.trial_start_time(i_trial) = trial_start_time;
        recordings.stim_onset_time(i_trial) = stim_onset_time;
        recordings.type(i_trial) = stim_type_seq_full(i_trial);
        if stim_type_seq_full(i_trial) == "filler"
            recordings.cresp(i_trial) = "";
        elseif stim_type_seq_full(i_trial) == "one-back"
            recordings.cresp(i_trial) = "Left";
        else
            recordings.cresp(i_trial) = "Right";
        end
        recordings.resp(i_trial) = resp;
        recordings.acc(i_trial) = resp_acc;
        recordings.rt(i_trial) = resp_rt;
        if early_exit
            break
        end
    end
    % store recorded data
    log_dir = 'logs';
    if ~exist(log_dir, 'dir')
        mkdir(log_dir)
    end
    save(fullfile(log_dir, ...
        sprintf('One-back-animal_sub%02d_%s', ...
        id, matlab.lang.makeValidName(string(time)))), ...
        'participant_info', 'recordings');
    % goodbye
    goodbye = ['已完成测验', ...
        '\n非常感谢您的配合！', ...
        '\n', ...
        '\n按任意键退出'];
    DrawFormattedText(window_ptr, double(goodbye), 'center', 'center', [0, 0, 1]);
    Screen('Flip', window_ptr);
    KbStrokeWait;
    Screen('Close');
catch exception
    status = 1;
end
sca;
ListenChar(1);
ShowCursor;
% restore preferences
Screen('Preference', 'VisualDebugLevel', old_visdb);
Screen('Preference', 'SkipSyncTests', old_sync);
Priority(priority_old);
end

function [spl, idx] = sample(set, k, exclude)
% SAMPLE randomly selects from SET without replacement

if nargin < 3
    exclude = [];
end
set = setdiff(set, exclude);
length_set = length(set);
if nargin < 2
    k = length(set);
end
idx = randperm(length_set, k);
spl = set(idx);
end