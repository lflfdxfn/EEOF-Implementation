function [] = algo_list(exp_method, result_runs_dir, i_run, params)
    % fetch data path
    file_data = params.data_path;

    % fetch parameters
    a = params.algo_a;% options.eta
    b = params.algo_b;% options.lamda
    c = params.algo_c;% KernelOptions.t
    e = params.algo_e;% decay factor
    disp_threshold = params.disp_threshold;

    
    % generate target result data files
    pred_data = sprintf("%s/run_%d.txt",result_runs_dir, i_run);
    time_data = sprintf("%s/run_time_%d.mat", result_runs_dir, i_run);

    % info
    fprintf("Runnning... Serial number: %d\n", i_run)   
    
    % run algorithms (add new available algorithm here!)
    if strcmp(exp_method, "CBCE")
        CBCE(file_data, pred_data, time_data, a, b, c, e, disp_threshold);
    elseif strcmp(exp_method, "EEOF")
        EEOF(file_data, pred_data, time_data, a, b, c, e, disp_threshold);
    else
        fprintf("No Algorithm is Found!")
    end
end

