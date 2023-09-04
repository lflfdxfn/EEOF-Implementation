clear;clc;f=genpath(pwd);addpath(f);

%% Settings
exp_methods = ["CBCE", "EEOF"];
origin_data = ["laden_ce.mat", "wed_ce.mat", "christ_ce.mat","kddcup99.mat", "pokerlsn.mat", "huge_tweet.mat"];
data_path = "../datasets";
window_sizes = [200];

if_train_model = true;
if_parallel = 0;
n_runs = 10;
base_method = "CBCE";       

data_names = [];
for idx_origin = 1:numel(origin_data)
    data_names = [data_names, sprintf("%s", origin_data(idx_origin))];
end

for idx_exp = 1:numel(exp_methods)
    for idx_data = 1:numel(data_names)
        exp_method = exp_methods(idx_exp);
        data_name = data_names(idx_data);
        table_name = sprintf("../%s.csv", data_name);
                
        run_algorithm(exp_method, data_path, data_name, table_name, base_method, if_train_model, if_parallel, n_runs, window_sizes)
    end
end