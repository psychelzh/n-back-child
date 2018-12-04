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
