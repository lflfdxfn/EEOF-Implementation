function [result_dir, result_runs_dir, result_analyze_dirs] = check_sliding_dirs(exp_name, data_name, window_sizes)
    
    result_dir = sprintf("../results/%s/%s", exp_name, data_name);
    
    % whether run results dirs exists
    result_runs_dir = sprintf("%s/runs",result_dir);    
    if ~exist(result_runs_dir, 'dir')
        mkdir(result_runs_dir)
    end

    % whether analyze results dirs exists
    result_analyze_dirs = [];

    for idx_ws = 1:numel(window_sizes)
        window_size = window_sizes(idx_ws);

        result_analyze_dir = sprintf("%s/sliding_%d", result_dir, window_size);
        result_analyze_dirs = [result_analyze_dirs, result_analyze_dir];
        if ~exist(result_analyze_dir, 'dir')
            mkdir(result_analyze_dir)
        end
    end
end

