function [] = store_in_csv(table_name, dataset_name, algo_name, value)
% file_name: the name of the stored excel table file
% dataset_name: the name of the corresponding dataset
% algo_name: the name of the algorithm
% value: the stored value in the excel table file\

    % store in excel and csv file
    csv_name = sprintf("%s", table_name);
    if ~exist(csv_name, 'file')
        new_csv_file = fopen(csv_name, 'a+');
        fclose(new_csv_file);
    end

    % csv_import
    opts = detectImportOptions(csv_name, 'Delimiter', ',');
    opts.VariableTypes(:) = {'char'};
    opts.PreserveVariableNames = true;
    origin_table = readtable(csv_name, opts);
    
    % if it is a new table
    if isempty(origin_table.Properties.VariableNames)
        origin_table.Var1 = "";
        origin_table = origin_table(false, :);
    end
    [n_row, n_col] = size(origin_table);

    % get the col names
    algorithms = origin_table.Properties.VariableNames;

    % convert all cols into strings
    dataset_names = origin_table{:,1};

    data_loc = find(strcmp(dataset_names, dataset_name));
    alg_loc = find(strcmp(algorithms, algo_name));
    
    if isempty(alg_loc)
        init_col = string(zeros(n_row, 1));
        init_col(:) = "";
        origin_table.NewAlg = init_col;
        origin_table.Properties.VariableNames('NewAlg') = algo_name;

        [n_row, n_col] = size(origin_table);
        alg_loc = n_col;
    end

    if isempty(data_loc)
        origin_table{n_row+1, 1} = {dataset_name};

        for idx_col = 2:n_col
            origin_table{n_row+1, idx_col} = {""};
        end

        [n_row, n_col] = size(origin_table);
        data_loc = n_row;
    end

    % store data
    origin_table{data_loc, alg_loc} = {value};

    writetable(origin_table, csv_name);
end

