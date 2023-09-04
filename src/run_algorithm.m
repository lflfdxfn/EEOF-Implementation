function [] = run_algorithm(exp_method, data_path, data_name, table_name, base_method, if_train_model, if_parallel, n_runs, window_sizes)
    Settings = algo_settings(data_name, data_path);
    
    % print out experimental settings
    fprintf("Experimental Settings:\n\tNum of runs: %d\n", n_runs)
    
    %% Running
    % check directory first
    [result_dir, result_runs_dir, result_analyze_dirs] = check_sliding_dirs(exp_method, data_name, window_sizes);
    
    pred_head = sprintf("%s/run",result_runs_dir);
    
    % diary on
    diary(sprintf("%s/log.txt", result_dir))
    diary on;
    
    % check dataset, parameters, and whether have run
    fprintf("Method: %s\n", exp_method)
    Settings.print_info(); % check parameter settings
    
    % begin to running
    if if_train_model
        if if_parallel~=0
            parpool('Processes',if_parallel);
            parfor i_run=1:n_runs
                rng(i_run, 'Threefry');
                algo_list(exp_method, result_runs_dir, i_run, Settings)
            end
            delete(gcp('nocreate'));
        else
            for i_run=1:n_runs
                rng(i_run, 'Threefry');
                algo_list(exp_method, result_runs_dir, i_run, Settings)
            end
        end         
    end

    fprintf("Evaluation Settings:\n\tWindow size: %s\n", mat2str(window_sizes))
    
    for idx_window = 1:numel(window_sizes)
        window_size = window_sizes(idx_window);
        result_analyze_dir = result_analyze_dirs(idx_window);
    
        %% Evaluation
        sliding_result = sprintf("%s/runs_sliding_%d.mat", result_dir, window_size);
        eval_sliding(pred_head, sliding_result, Settings.data_n_example, Settings.data_n_classes, n_runs, window_size)
    
        %% Store scenario infos in Excel
        scenario_data = load(Settings.data_path);
        
        if Settings.if_scenarios
            write_table_header("../scenario_infos.csv", scenario_data);
        end
        
        %% Ploting Sliding Metrics
        sliding_analyze = load(sliding_result);
        
        sliding_gmean_matrix_runs = sliding_analyze.sliding_gmean_matrix_runs;
    
        if strcmp(base_method, "")
            %% Average of Sliding Window G-mean (% Overall Performance)
            mean_of_sliding_gmean_runs = mean(sliding_gmean_matrix_runs, 1, 'omitnan');
            stored_string = sprintf("%.4f/%.4f", mean(mean_of_sliding_gmean_runs), std(mean_of_sliding_gmean_runs));

            store_in_csv(table_name, sprintf("G-mean (%d)", window_size), exp_method, stored_string);
        else
            %% Compare the performance statistically
            % run experiments and store predictions and evaluations
            base_result = sprintf("../results/%s/%s/runs_sliding_%d.mat", base_method, data_name, window_size);
            % load result data and extract sliding g-means result for analysis
            base_sliding_analyze = load(base_result);
            base_sliding_gmean_matrix_runs = base_sliding_analyze.sliding_gmean_matrix_runs;
            
            %% Average of Sliding Window G-mean (% Overall Performance)
            mean_of_sliding_gmean_runs = mean(sliding_gmean_matrix_runs, 1, 'omitnan');
            base_mean_of_sliding_gmean_runs = mean(base_sliding_gmean_matrix_runs, 1, 'omitnan');
        
            stored_string = wrst(exp_method, mean_of_sliding_gmean_runs, base_method, base_mean_of_sliding_gmean_runs);
            store_in_csv(table_name, sprintf("Average of Sliding Window G-mean (%d)", window_size), exp_method, stored_string);
        end
    end
    
    fclose('all'); % avoid opening too many file error.
    diary off;
end

function [stored_string] = wrst(comp_method, comp_result, base_method, base_result)
        % p-value calculate    
    p = ranksum(comp_result, base_result);

    % mean values
    mean_of_comp_result = mean(comp_result);
    mean_of_base_result = mean(base_result);
    
    %%% Store mean of gmean result in an excel file
    if strcmp(comp_method, base_method)
        stored_string = sprintf("%.4f/%.4f", mean_of_base_result, std(base_result));
    elseif ( mean_of_comp_result > mean_of_base_result ) && (p<0.05)
        stored_string = sprintf("%.4f/%.4f +", mean_of_comp_result, std(comp_result));
    elseif ( mean_of_comp_result < mean_of_base_result ) && (p<0.05)
        stored_string = sprintf("%.4f/%.4f -", mean_of_comp_result, std(comp_result));
    else
        stored_string = sprintf("%.4f/%.4f =", mean_of_comp_result, std(comp_result));
    end
end

function [] = write_table_header(table_name, scenario_data)
    store_in_csv(table_name, scenario_data.save_header, "Dataset", sprintf("%s", scenario_data.data_name))
    store_in_csv(table_name, scenario_data.save_header, "N_Existing", sprintf("%d", scenario_data.n_existing));

    if isfield(scenario_data, 'n_emerging')
        store_in_csv(table_name, scenario_data.save_header, "N_Emerging", sprintf("%d", scenario_data.n_emerging));
        store_in_csv(table_name, scenario_data.save_header, "Max_Values", mat2str(scenario_data.max_values, 4));
        store_in_csv(table_name, scenario_data.save_header, "Mean_points", mat2str(scenario_data.mean_points, 4));
        store_in_csv(table_name, scenario_data.save_header, "Gaussian_Stds", mat2str(scenario_data.gaussian_stds, 4));
        store_in_csv(table_name, scenario_data.save_header, "Disp_or_Not", mat2str(scenario_data.disp_or_nots, 4));
        store_in_csv(table_name, scenario_data.save_header, "E_Durations", mat2str(scenario_data.e_durations, 4));
        store_in_csv(table_name, scenario_data.save_header, "Chunk_Size", sprintf("%d", scenario_data.chunk_size));
        store_in_csv(table_name, scenario_data.save_header, "N_Chunk", sprintf("%d", scenario_data.n_chunk));
        store_in_csv(table_name, scenario_data.save_header, "Seed", sprintf("%d", scenario_data.seed));
    else
        store_in_csv(table_name, scenario_data.save_header, "Disp_Point", sprintf("%d", scenario_data.disp_point));
        store_in_csv(table_name, scenario_data.save_header, "Disp_Dura", sprintf("%d", scenario_data.zero_dura));
        store_in_csv(table_name, scenario_data.save_header, "Reoccur_Dura", sprintf("%d", scenario_data.reoccur_dura));
        store_in_csv(table_name, scenario_data.save_header, "Gaussian_Stds", mat2str(scenario_data.gaussian_std, 4));
        store_in_csv(table_name, scenario_data.save_header, "Chunk_Size", sprintf("%d", scenario_data.chunk_size));
        store_in_csv(table_name, scenario_data.save_header, "N_Chunk", sprintf("%d", scenario_data.n_chunk));
        store_in_csv(table_name, scenario_data.save_header, "Seed", sprintf("%d", scenario_data.seed));
    end
end