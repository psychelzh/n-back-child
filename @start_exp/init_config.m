function config = init_config(app, part)
%GENSEQ generates sequence for current study and stores in a `.csv` file
%
%   The basic thing to do here is to generate sequence for our experiment
%   test, which contains two parts: practice (part: 'prac') and testing
%   (part: 'test'). Generally, a **fixed** pseudorandom sequence is
%   required for testing part but not for practice part. Thus, the random
%   number generation of testing part seed is set as 0 for each user,
%   whereas that of practice part is set as 'Shuffle'.

% set all the task names
task_names = ["zero-back", "one-back", "two-back"];
disp_names = ["0¼¶", "1¼¶", "2¼¶"];
map_names = containers.Map(task_names, disp_names);
% configure 
switch part
    case 'prac'
        % set different random seed for each user
        rng('Shuffle')
        run_blocks = {randsample(task_names, length(task_names))};
    case 'test'
        % fix random seed to ensure sequences for all users are the same
        rng(0)
        % testing part has two runs, and each run has three blocks
        block_names_regular = perms(task_names)';
        run_blocks = cellfun(@(x) x(:), ...
            {block_names_regular(:, 1:3), block_names_regular(:, 4:6)}, ...
            'UniformOutput', false);
end
% generate sequence for each run and each block
num_runs = length(run_blocks);
config.runs = repelem(struct, num_runs);
for i_run = 1:num_runs
    block_names = run_blocks{i_run};
    num_blocks = length(block_names);
    config.runs(i_run).blocks = repelem(struct, num_blocks);
    for i_block = 1:num_blocks
        block_name = block_names(i_block);
        config.runs(i_run).blocks(i_block).id = i_block;
        config.runs(i_run).blocks(i_block).name = block_name;
        config.runs(i_run).blocks(i_block).disp_name = map_names(block_name);
        config.runs(i_run).blocks(i_block).trials = ...
            gen_block_seq(app.StimuliSet, app.NumberTrialsPerBlock, block_name);
    end
end
rng('default')
end

function seq = gen_block_seq(stim_set, num_trials, task_name)
% GENBLOCKSEQ generates sequence for each block

% configurations
trial_types = ["filler", "target", "distractor"];
% generate trial type sequence
type_population = repelem(trial_types(trial_types ~= "filler"), ...
    num_trials / sum(trial_types ~= "filler"));
type = randsample(type_population, length(type_population));
% preallocate
stim = nan(1, length(type));
% generate sequence
switch task_name
    case "zero-back"
        % "target" is numbers smaller than 5, and "distractor" otherwise
        stim(type == "target") = randsample(stim_set(stim_set < 5), num_trials / 2, true);
        stim(type == "distractor") = randsample(stim_set(stim_set >= 5), num_trials / 2, true);
    case "one-back"
        % the first should be "filler"
        type(1) = "filler";
        for itrial = 1:num_trials
            if type(itrial) == "filler"
                stim(itrial) = randsample(stim_set, 1);
            end
            if type(itrial) == "target"
                stim(itrial) = stim(itrial - 1);
            end
            if type(itrial) == "distractor"
                stim(itrial) = randsample(stim_set, 1, true, ~ismember(stim_set, stim(itrial - 1)));
            end
        end
    case "two-back"
        % the first two trials should be "filler"
        type(1:2) = "filler";
        for itrial = 1:num_trials
            if type(itrial) == "filler"
                if itrial == 1
                    exclude = [];
                else
                    exclude = stim(itrial - 1);
                end
                stim(itrial) = randsample(stim_set, 1, true, ~ismember(stim_set, exclude));
            end
            if type(itrial) == "target"
                stim(itrial) = stim(itrial - 2);
            end
            if type(itrial) == "distractor"
                stim(itrial) = randsample(stim_set, 1, true, ~ismember(stim_set, stim(itrial - 2:itrial - 1)));
            end
        end
    otherwise
        error('NBACKCHILD:init_cofig:genblockseq:invalidTaskName', ...
            'Task name ''%s'' is not supported now.', task_name);
end
% set the correct response sequence
cresp = strings(1, length(type));
cresp(type == "target") = "Left";
cresp(type == "distractor") = "Right";
% set cue properties
cue.id = 0;
cue.type = "cue";
cue.cresp = "";
cue.stim = nan;
seq = [cue, struct('id', num2cell(1:num_trials), 'type', num2cell(type), ...
    'cresp', num2cell(cresp), 'stim', num2cell(stim))];
end
