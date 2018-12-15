function init_config(app)
%GENSEQ generates sequence for current study and stores in a `.csv` file

% set random seed as the same to ensure the same sequence is generated
rng(0)
% initialize configurtion
config = struct;
config.experiment_name = app.ExperimentName;
parts = ["prac", "test"];
for part = parts
    % configure block sequence
    task_names = ["back0", "back1", "back2"]';
    switch part
        case 'prac'
            block_names = task_names;
        case 'test'
            block_names = perms(task_names);
            block_names = block_names(:);
    end
    % generate sequence for each block
    num_blocks = length(block_names);
    num_trial_each_block = 10;
    seq_part = repelem(struct, num_blocks);
    for i_block = 1:num_blocks
        block_name = block_names(i_block);
        [seq_stim, seq_type] = ...
            genblockseq(num_trial_each_block, block_name);
        seq_part(i_block).block_id = i_block;
        seq_part(i_block).block_name = block_name;
        seq_part(i_block).seq_trial.stim = seq_stim;
        seq_part(i_block).seq_trial.type = seq_type;
    end
    config.sequence.(part) = seq_part;
end
% output as json config file
config_file = fopen(app.ConfigFileName, 'w');
fprintf(config_file, '%s', jsonencode(config));
fclose(config_file);
% restore seed for random number generation to default
rng('default')
end

function [seq_stim, seq_type] = genblockseq(num_trials, task_name)
% GENBLOCKSEQ generates sequence for each block

% stimuli set
stim_set = 0:9;
% generate trial type sequence
trial_types = ["target", "distractor"];
seq_type = sample(repelem(trial_types, num_trials / length(trial_types)));
% generate sequence
switch task_name
    case "back0"
        % "target" is numbers smaller than 5, and "distractor" otherwise
        seq_stim(seq_type == "target") = sample(stim_set(stim_set < 5));
        seq_stim(seq_type == "distractor") = sample(stim_set(stim_set >= 5));
    case "back1"
        % the first should be "filler"
        seq_type(1) = "filler";
        seq_stim = nan(1, num_trials);
        for itrial = 1:num_trials
            if seq_type(itrial) == "filler"
                seq_stim(itrial) = sample(stim_set, 1);
            end
            if seq_type(itrial) == "target"
                seq_stim(itrial) = seq_stim(itrial - 1);
            end
            if seq_type(itrial) == "distractor"
                seq_stim(itrial) = sample(stim_set, 1, seq_stim(itrial - 1));
            end
        end
    case "back2"
        % the first two trials should be "filler"
        seq_type(1:2) = "filler";
        seq_stim = nan(1, num_trials);
        for itrial = 1:num_trials
            if seq_type(itrial) == "filler"
                if itrial == 1
                    exclude = [];
                else
                    exclude = seq_stim(itrial - 1);
                end
                seq_stim(itrial) = sample(stim_set, 1, exclude);
            end
            if seq_type(itrial) == "target"
                seq_stim(itrial) = seq_stim(itrial - 2);
            end
            if seq_type(itrial) == "distractor"
                seq_stim(itrial) = sample(stim_set, 1, seq_stim(itrial - 2:itrial - 1));
            end
        end
    otherwise
        error('NBACKCHILD:initcofig:genblockseq:invalidTask', ...
            'Task name ''%s'' is not supported now.', task_name);
end
end

function [spl, idx] = sample(set, k, exclude)
% SAMPLE randomly selects from SET without replacement

if nargin < 3
    exclude = [];
end
if ~isempty(exclude)
    set = setdiff(set, exclude);
end
length_set = length(set);
if nargin < 2
    k = length(set);
end
idx = randperm(length_set, k);
spl = set(idx);
end