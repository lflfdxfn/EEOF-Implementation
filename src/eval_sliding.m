function [] = eval_sliding(result_head, exp_result, example_cnt, class_cnt, runs, window_size)
% result_head: prediction file head (without number of run) made by CBCE
% exp_result: store path of the experimental results, such as recall, gmean
% example_cnt: the size of total data
% class_cnt: the number of classes
% runs: number of runs    
% window_size: the size of the sliding window

    sliding_recall_matrix_runs = zeros(example_cnt, class_cnt, runs);
    sliding_recall_matrix_runs(:) = NaN;

    for idx_run = 1:runs
        file_name = sprintf('%s_%d.txt',result_head, idx_run);

        opts = detectImportOptions(file_name, "Delimiter"," ");
        pred_table = readmatrix(file_name, opts);

        for t_count = window_size:example_cnt
            window_pred = pred_table((t_count-window_size+1):t_count, 1:2);
            
            real_labels = window_pred(:, 1);
            pred_labels = window_pred(:, 2);
            correct_or_not = real_labels == pred_labels;

            classes = unique(real_labels);
            for idx_cls = 1:numel(classes)
                class = classes(idx_cls);
                
                class_mask = real_labels == class;

                sliding_recall_matrix_runs(t_count, class, idx_run) = sum(correct_or_not(class_mask))/sum(class_mask);
            end
        end
    end

    sliding_gmean_matrix_runs = squeeze(geomean(sliding_recall_matrix_runs, 2, 'omitnan'));

    save(exp_result,'sliding_recall_matrix_runs', 'sliding_gmean_matrix_runs', 'window_size');
end