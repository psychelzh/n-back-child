function [status, exception] = start_nback(app, varargin)
% Copyright (C) 2018, Liang Zhang - All Rights Reserved.
% @author      Liang Zhang <psychelzh@outlook.com>
% @description This script is used to display stimuli in fMRI research
%              based on one-back paradigm, using Psychtoolbox as devtool.

% please mannually make sure Psychtoolbox is installed

% ---- check input arguments ----
p = inputParser;
expected_parts = ["prac", "test"];
expected_tasks = ["zero-back", "one-back", "two-back"];
p.addParameter('Part', 'prac', @(x) any(expected_parts == x))
p.addParameter('Run', 1, @isnumeric)
% "Task" param is silently ignored when "Part" param is test
p.addParameter('Task', [], @(x) any(expected_tasks == x))
p.parse(varargin{:})
part = string(p.Results.Part);
run = p.Results.Run;
task = string(p.Results.Task);

% ---- set default output ----
status = 0;
exception = [];

% ---- prepare sequences ----
config = app.init_config(part);
run_active = config.runs(run);
% select the specified task when in practice part
if part == "prac" && ~isempty(task)
    run_active = run_active([run_active.blocks.name] == task);
end
num_trials_total = sum(cellfun(@length, {run_active.blocks.trials}));

% ----prepare data recording table ----
vars_trial_configs = {'trial_id', 'block', 'task', 'trial', 'type', 'stim'};
dflt_trial_configs = {nan, nan, strings, nan, strings, nan};
vars_trial_timing = {'trial_start_time_expt', 'trial_start_time', 'stim_onset_time', 'stim_offset_time'};
dflt_trial_timing = {nan, nan, nan, nan};
vars_trial_resp = {'cresp', 'resp', 'resp_raw', 'acc', 'rt'};
dflt_trial_resp = {strings, strings, strings, nan, nan};
recordings = cell2table( ...
    repmat([dflt_trial_configs, dflt_trial_resp, dflt_trial_timing], num_trials_total, 1), ...
    'VariableNames', [vars_trial_configs, vars_trial_resp, vars_trial_timing]);

% ---- configure screen and window ----
% setup default level of 2
PsychDefaultSetup(2);
% screen selection
screen_to_display = max(Screen('Screens'));
% set the start up screen to black
old_visdb = Screen('Preference', 'VisualDebugLevel', 1);
% do not skip synchronization test to make sure timing is accurate
old_sync = Screen('Preference', 'SkipSyncTests', 0);
% set priority to the top
old_pri = Priority(MaxPriority(screen_to_display));

try % error proof programming
    % ---- open window ----
    % open a window and set its background color as gray
    gray = WhiteIndex(screen_to_display) / 2;
    window_ptr = PsychImaging('OpenWindow', screen_to_display, gray);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name and size
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, 128);

    % ---- timing information ----
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    % stimulus time boundaries for each trial:
    %  the first: stimulus onset
    %  the second: stimulus offset
    %  the third: trial end (or time length of one trial)
    stim_bound = cumsum([app.TimeFixationSecs, app.TimeStimuliSecs, app.TimeBlankSecs]);
    
    % ---- keyboard settings ----
    keys.start = KbName('s');
    keys.exit = KbName('Escape');
    switch part
        case 'prac'
            keys.left = KbName('LeftArrow');
            keys.right = KbName('RightArrow');
        case 'test'
            keys.left = KbName('1!');
            keys.right = KbName('4$');
    end

    % ---- present stimuli ----
    % display welcome screen and wait for a press of 's' to start
    [welcome_img, ~, welcome_alpha] = ...
        imread(fullfile(app.ImageFilePath, 'welcome.png'));
    welcome_img(:, :, 4) = welcome_alpha;
    welcome_tex = Screen('MakeTexture', window_ptr, welcome_img);
    Screen('DrawTexture', window_ptr, welcome_tex);
    Screen('Flip', window_ptr);
    % the flag to determine if the experiment should exit early
    early_exit = false;
    % here we should detect for a key press and release
    while true
        [resp_time, resp_code] = KbStrokeWait(-1);
        if resp_code(keys.start)
            start_time = resp_time;
            break
        elseif resp_code(keys.exit)
            early_exit = true;
            break
        end
    end
    % present a fixation cross to wait user perpared in test part
    if ~early_exit && part == "test"
        % test cannot be stopped here
        DrawFormattedText(window_ptr, '+', 'center', 'center', [0, 0, 0]);
        Screen('Flip', window_ptr);
        trial_next_start_time_expt = app.TimeWaitStartSecs;
    end
    trial_order = 0;
    % a block contains a task cue and several trials
    for block = run_active.blocks
        if early_exit
            break
        end
        % display instruction when separately practicing
        if part == "prac" && ~isempty(task)
            [instruction_img, ~, instruction_alpha] = ...
                imread(fullfile(app.ImageFilePath, sprintf('%s.png', block.name)));
            instruction_img(:, :, 4) = instruction_alpha;
            instruction_tex = Screen('MakeTexture', window_ptr, instruction_img);
            Screen('DrawTexture', window_ptr, instruction_tex);
            Screen('Flip', window_ptr);
            while true
                [resp_time, resp_code] = KbPressWait(-1);
                if resp_code(keys.exit)
                    early_exit = true;
                    break
                elseif resp_code(keys.start)
                    start_time = resp_time;
                    trial_next_start_time_expt = 0;
                    break
                end
            end
        end
        % there are two kinds of trials: task cue trials and stimuli trials
        for trial = block.trials
            if early_exit
                break
            end
            % store trial information
            trial_order = trial_order + 1;
            recordings.trial_id(trial_order) = trial_order;
            recordings.block(trial_order) = block.id;
            recordings.task(trial_order) = block.name;
            recordings.trial(trial_order) = trial.id;
            recordings.stim(trial_order) = trial.stim;
            recordings.type(trial_order) = trial.type;
            recordings.cresp(trial_order) = trial.cresp;
            % a flag variable indicating if user has pressed a key
            resp_made = false;
            trial_start_time_expt = trial_next_start_time_expt;
            % task cue trial only present a cue indicating the task set
            if trial.type == "cue"
                trial_next_start_time_expt = ...
                    trial_next_start_time_expt + app.TimeTaskCueSecs;
                % draw the cue indicating block task name and wait for a
                % press of `Esc` to exit
                DrawFormattedText(window_ptr, double(block.disp_name), ...
                    'center', 'center', [1, 0, 0]);
                trial_start_timestamp = ...
                    Screen('Flip', window_ptr, ...
                    start_time + trial_start_time_expt - 0.5 * ifi);
                [~, resp_code] = ...
                    KbPressWait(-1, start_time + trial_next_start_time_expt - 0.5 * ifi);
                if resp_code(keys.exit)
                    early_exit = true;
                end
            else % stimulus trial contains a fixation cross, a stimulus and a blank screen
                trial_next_start_time_expt = trial_next_start_time_expt + stim_bound(3);
                % set the timing boundray of three phases of a trial
                trial_bound = trial_start_time_expt + stim_bound;
                % draw fixation and wait for press of `Esc` to exit
                DrawFormattedText(window_ptr, '+', ...
                    'center', 'center', [0, 0, 0]);
                trial_start_timestamp = ...
                    Screen('Flip', window_ptr, ...
                    start_time + trial_start_time_expt - 0.5 * ifi);
                [~, resp_code] = ...
                    KbPressWait(-1, start_time + trial_bound(1) - 0.5 * ifi);
                if resp_code(keys.exit)
                    early_exit = true;
                    break
                end
                % set the color for stimuli that not requiring response as
                % red (the same as task cue), and as black otherwise
                if trial.type == "filler"
                    DrawFormattedText(window_ptr, num2str(trial.stim), ...
                        'center', 'center', [1, 0, 0]);
                else
                    DrawFormattedText(window_ptr, num2str(trial.stim), ...
                        'center', 'center', [0, 0, 0]);
                end
                stim_onset_timestamp = Screen('Flip', window_ptr, ...
                    start_time + trial_bound(1) - 0.5 * ifi);
                [resp_timestamp, resp_code] = ...
                    KbPressWait(-1, start_time + trial_bound(2) - 0.5 * ifi);
                if resp_code(keys.exit)
                    early_exit = true;
                    break
                end
                if any(resp_code)
                    resp_made = true;
                end
                % blank screen to wait for user's reponse
                Screen('FillRect', window_ptr, gray);
                stim_offset_timestamp = Screen('Flip', window_ptr, ...
                    start_time + trial_bound(2) - 0.5 * ifi);
                if ~resp_made
                    [resp_timestamp, resp_code] = ...
                        KbPressWait(-1, start_time + trial_bound(3) - 0.5 * ifi);
                    if resp_code(keys.exit)
                        early_exit = true;
                        break
                    end
                    if any(resp_code)
                        resp_made = true;
                    end
                end
                % analyze user's response
                if ~resp_made
                    resp = "";
                    resp_raw = "";
                    resp_acc = -1;
                    resp_time = 0;
                else
                    resp_time = resp_timestamp - stim_onset_timestamp;
                    % use "|" as delimiter for the KeyName of "|" is "\\"
                    resp_raw = string(strjoin(cellstr(KbName(resp_code)), '|'));
                    if ~resp_code(keys.left) && ~resp_code(keys.right)
                        resp = "Neither";
                    elseif resp_code(keys.left) && resp_code(keys.right)
                        resp = "Both";
                    elseif resp_code(keys.left)
                        resp = "Left";
                    else
                        resp = "Right";
                    end
                    if trial.type ~= "filler"
                        resp_acc = double(resp == trial.cresp);
                    end
                end
                % if practice, give feedback
                if part == "prac"
                    % set a smaller text size to display text feedback
                    old_text_size = Screen('TextSize', window_ptr, 64);
                    if trial.type == "filler" && resp_made
                        feedback_msg = '还不是按键的时候';
                        feedback_color = [1, 1, 1];
                    else
                        switch resp_acc
                            case -1
                                feedback_msg = '超时了\n\n请及时作答';
                                feedback_color = [1, 1, 1];
                            case 0
                                switch resp
                                    case "Neither"
                                        feedback_msg = '按错键了';
                                    case "Both"
                                        feedback_msg = '请不要同时按左右键';
                                    otherwise
                                        feedback_msg = '错了（×）\n\n不要灰心';
                                end
                                feedback_color = [1, 0, 0];
                            case 1
                                feedback_msg = '对了（√）\n\n真棒';
                                feedback_color = [0, 1, 0];
                        end
                    end
                    % no feedback if no response to "filler" stimuli
                    if ~(trial.type == "filler" && ~resp_made)
                        DrawFormattedText(window_ptr, double(feedback_msg), 'center', 'center', feedback_color);
                        Screen('Flip', window_ptr, start_time + trial_bound(3) - 0.5 * ifi);
                        WaitSecs(app.TimeFeedbackSecs);
                        trial_next_start_time_expt = trial_next_start_time_expt + app.TimeFeedbackSecs;
                    end
                    % restore default larger text size
                    Screen('TextSize', window_ptr, old_text_size);
                end
                % store stimulus trial special data
                recordings.stim_onset_time(trial_order) = stim_onset_timestamp - start_time;
                recordings.stim_offset_time(trial_order) = stim_offset_timestamp - start_time;
                recordings.resp(trial_order) = resp;
                recordings.resp_raw(trial_order) = resp_raw;
                recordings.acc(trial_order) = resp_acc;
                recordings.rt(trial_order) = resp_time;
            end
            % store common trial data
            recordings.trial_start_time_expt(trial_order) = trial_start_time_expt;
            recordings.trial_start_time(trial_order) = trial_start_timestamp - start_time;
        end
    end
    % present a fixation cross before ending in test part
    if ~early_exit && part == "test"
        % test cannot be stopped here
        DrawFormattedText(window_ptr, '+', 'center', 'center', [0, 0, 0]);
        Screen('Flip', window_ptr);
        WaitSecs(app.TimeWaitEndSecs);
    end
    % goodbye
    [ending_img, ~, ending_alpha] = ...
        imread(fullfile(app.ImageFilePath, 'ending.png'));
    ending_img(:, :, 4) = ending_alpha;
    ending_tex = Screen('MakeTexture', window_ptr, ending_img);
    Screen('DrawTexture', window_ptr, ending_tex);
    Screen('Flip', window_ptr);
    KbStrokeWait;
catch exception
    status = 1;
end
% clear jobs
Screen('Close');
sca;
% save recorded data
switch part
    case 'prac'
        data_store_name = sprintf('%s_rep%d', part, app.UserPracticedTimes);
    case 'test'
        data_store_name = sprintf('%s_run%d', part, run);
end
S.(data_store_name).config = config;
S.(data_store_name).recordings = recordings;
save(fullfile(app.LogFilePath, app.LogFileName), ...
    '-struct', 'S', '-append')
% enable character input and show mouse cursor
ListenChar(1);
ShowCursor;
% restore preferences
Screen('Preference', 'VisualDebugLevel', old_visdb);
Screen('Preference', 'SkipSyncTests', old_sync);
Priority(old_pri);
end
