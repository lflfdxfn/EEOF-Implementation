classdef algo_settings
    %DATASET 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        name
        data_dir
        data_path
        data_n_example
        data_n_dim
        data_n_classes
        data_appear_time
        
        algo_a % options.eta
        algo_b % options.lamda
        algo_c % KernelOptions.t
        algo_e % decay factor

        disp_threshold % default value of disappearing threshold

        if_scenarios
    end
    
    methods
        function obj = algo_settings(name, data_dir)
            % store parameters chosen for these datasets
            obj.name = name;
            obj.data_dir = data_dir;
            obj.data_path = sprintf("%s/%s",data_dir, name);

            x = load(obj.data_path,'x');
            y = load(obj.data_path,'y');
            x = x.x;
            y = y.y;

            [obj.data_n_dim,obj.data_n_example] = size(x);
            obj.data_n_classes = numel(unique(y));

            obj.data_appear_time = zeros(1, obj.data_n_classes);
            for idx_cls = 1:obj.data_n_classes
                obj.data_appear_time(idx_cls) = find(y==idx_cls, 1);
            end

            obj.disp_threshold = 0.00001;
            obj.if_scenarios = false;

            if strcmp(obj.name, 'laden_ce.mat')
                obj = obj.init_parameters(0.3, 0.0005, 0.13, 0.9);
            elseif strcmp(obj.name, 'wed_ce.mat')
                obj = obj.init_parameters(0.3, 0.0005, 0.13, 0.9);
            elseif strcmp(obj.name, 'christ_ce.mat')
                obj = obj.init_parameters(0.3, 0.0005, 0.13, 0.9);
            elseif strcmp(obj.name, 'huge_tweet.mat')
                obj = obj.init_parameters(0.3, 0.0005, 0.13, 0.9);
            elseif strfind(obj.name, 'letter_Scenario')
                obj = obj.init_parameters(0.01, 1, 1, 0.9);
                obj.if_scenarios = true;
            elseif strfind(obj.name, 'statlog_Scenario')
                obj = obj.init_parameters(0.01, 1, 14, 0.9);
                obj.if_scenarios = true;
            elseif strfind(obj.name, 'mnist_Scenario')
                obj = obj.init_parameters(6, 0.0001, 7, 0.9);
                obj.if_scenarios = true;
            elseif strfind(obj.name, 'covertype_Scenario')
                obj = obj.init_parameters(2, 0.0001, 5.4, 0.9);
                obj.if_scenarios = true;
            elseif strfind(obj.name, 'kddcup99')
                obj = obj.init_parameters(0.0001, 0.0001, 0.3, 0.9);
            elseif strfind(obj.name, 'pokerlsn')
                obj = obj.init_parameters(8, 0.001, 3.4, 0.9);
            else
                fprintf("No dataset is found!")
            end
        end
        
        function obj = init_parameters(obj, algo_a, algo_b, algo_c, algo_e)
            % assign values to these parameters
            obj.algo_a = algo_a;
            obj.algo_b = algo_b;
            obj.algo_c = algo_c;
            obj.algo_e = algo_e;
        end

        function [] = print_info(obj)
            % print data info
            fprintf("Dataset: %s\n", obj.name)
            fprintf("\tdata path: %s\n", obj.data_path)
            fprintf("\tn_examples: %d\n", obj.data_n_example)
            fprintf("\tn_dim: %d\n", obj.data_n_dim)
            fprintf("\tn_classes: %d\n", obj.data_n_classes)
            fprintf("\tappear time: %s\n", mat2str(obj.data_appear_time))

            % print parameters chosen for CBCE
            fprintf("Parameters Choose for CBCE:\n")
            fprintf("\teta: %s\n", string(obj.algo_a))
            fprintf("\tlamda: %s\n", string(obj.algo_b))
            fprintf("\tsigma: %s\n", string(obj.algo_c))
            fprintf("\tdecay factor: %s\n", string(obj.algo_e))
            fprintf("\tdisappearing threshold: %g\n", string(obj.disp_threshold))
        end
    end
end