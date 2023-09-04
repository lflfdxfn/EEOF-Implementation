clear;clc;f=genpath(pwd);addpath(f);

%% Settings
exp_methods = ["CBCE", "EEOF"];
origin_data = ["letter", "statlog", "covertype", "mnist"];
data_path = "../datasets/synthetic_datasets";

scenarios = [2, 3, 4, 5];
n_cases = [6, 5, 4, 1];
window_sizes = [200];

if_train_model = true;
if_parallel = 0;
n_runs = 10;
base_method = "CBCE";

data_names = [];
for idx_origin = 1:numel(origin_data)
    for idx_scenario = 1:numel(scenarios)
        scenario = scenarios(idx_scenario);
        
        for idx_case = 1:n_cases(idx_scenario)
            data_names = [data_names, sprintf("%s_Scenario%d_Case%d.mat", origin_data(idx_origin), scenario, idx_case)];
        end
    end
end

for idx_exp = 1:numel(exp_methods)
    for idx_data = 1:numel(data_names)
        exp_method = exp_methods(idx_exp);
        data_name = data_names(idx_data);
        table_name = sprintf("../%s.csv", data_name);
        
        run_algorithm(exp_method, data_path, data_name, table_name, base_method, if_train_model, if_parallel, n_runs, window_sizes)
    end
end