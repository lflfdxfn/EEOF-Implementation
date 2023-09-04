function [] = CBCE(file_data,file_result,outname,a,b,c,e,disp_threshold)
% file_data: the path to data file, containing x and y
% file_result: store the experiment results
% outname: store the time cost
% a: eta
% b: lambda
% c: t
% e: decay factor
% disp_threshold: disappearance threshold for CBCE

% Parameters
options.eta = a;
options.lamda = b;
KernelOptions.t = c;
ratio_decay = e;
options.cnt = 5000; % 每个KLR的最大存储数据容量。 这里采用truncation的策略，用完空间后，会自动覆盖最早的。

% class info
class_exist = [];
class_ratio = [];
class_ratio_initial = [];

% model initialization
ensemble = [];

% experiment result output
fid_result = fopen(file_result, 'w');

% load data stream
x = [];     %feature values
y = [];     %class labels
x = load(file_data,'x');
y = load(file_data,'y');
x = x.x;
y = y.y;
num_classes = numel(unique(y));
[dimension,example_count] = size(x);

%%read & classify example, update model
t_count=0;
tic;
while t_count<example_count
    t_count = t_count+1;

    real_label = y(t_count);
    new_example = x(:,t_count);
    real_index = find(class_exist==real_label);
    
    %%classify examples
    classifier_count = length(ensemble);
    ft_array = [];
    if(classifier_count>0)
        classify_result = zeros(1, classifier_count);
        ft_array = zeros(1, classifier_count);
        for i = 1 : classifier_count
            if(ensemble(i).active == 0)
                classify_result(i) = 0;
                ft_array(i) = NaN;
            else
                [classify_result(i),ft_array(i)] = OnlineKLRClassify(new_example,ensemble(i));
            end
        end
        [max_probability, predic_subscript] = max(classify_result);
        prediction = class_exist(predic_subscript);
    else
        prediction = 0;
        max_probability = 0.5;
    end
    
    fprintf(fid_result, '%d %d %f\n', real_label, prediction, max_probability);

    % update ratio and determine the class disappearance
    [class_exist, class_ratio, class_ratio_initial,class_disap,class_rec] = classRatioUpdate(class_exist, class_ratio, class_ratio_initial, real_label, disp_threshold);
    if(~isempty(class_disap))
        for i=1:length(class_disap)
            ensemble(class_disap(i)).active = 0;
        end
    end
    if(class_rec~=0)
        ensemble(class_rec).active = 1;
    end

    % update CB models
    real_subscript = find(class_exist==real_label);
    if(real_subscript == length(ensemble)+1)
       ensemble(real_subscript).currentAlpha = zeros(1,options.cnt);
       ensemble(real_subscript).norm2X = zeros(1,options.cnt);
       ensemble(real_subscript).trainFea = zeros(dimension,options.cnt);
       ensemble(real_subscript).index = 1;          %need update support vector
       ensemble(real_subscript).firstloop = 1;      %
       ensemble(real_subscript).active = 1;
       ft_array(end+1) = 0;
    end
    classifier_count = length(ensemble);
    
    for i = 1 : classifier_count
        label_tmp = 0;
        clf_class = class_exist(i);

        if(i == real_subscript)
            label_tmp = 1;                          %positive label          
        else           
            ratio_tmp = class_ratio(i);
            random_num = rand();
            select_ratio = ratio_tmp/(1-ratio_tmp);
            if (random_num < select_ratio)
               label_tmp = -1;                      %negative label
            end
        end
        
        if(label_tmp~=0)
            if(isnan(ft_array(i)))
                [~,ft_array(i)] = OnlineKLRClassify(new_example,ensemble(i));
            end
            [param,new_alpha,new_norm] = OnlineKLRUpdate(new_example,label_tmp,ft_array(i),ensemble(i));
            ensemble(i).currentAlpha = param*ensemble(i).currentAlpha;
            ensemble(i).currentAlpha(ensemble(i).index) = new_alpha;
            ensemble(i).norm2X(ensemble(i).index) = new_norm;
            ensemble(i).trainFea(:,ensemble(i).index) = new_example;
            ensemble(i).index = ensemble(i).index+1;
            if(ensemble(i).index>options.cnt)
                ensemble(i).index = 1;
                ensemble(i).firstloop = 0;
            end
        end
    end
end
time = toc;
fclose(fid_result);
save(outname,'time');

    %%classify
    function [prob_yt_ft,ft_xt] = OnlineKLRClassify(xt,model)
        if(model.firstloop==1)
            T = model.index - 1;
        else
            T = options.cnt;
        end
        sigma=KernelOptions.t;

        norm2xt=sum(xt.*xt);

        % Depends on the kernel
        k_xt=construct_RBF_Row(norm2xt,model.norm2X(1:T),xt'*model.trainFea(:,1:T),sigma);
        ft_xt=k_xt*model.currentAlpha(1:T)';

        prob_yt_ft=LogisticProb(-ft_xt);
    end

    %update
    function [param,new_alpha,new_norm] = OnlineKLRUpdate(xt,yt,ft_xt,model)  
        % Columns are samples
        % Optimized for Gaussian Kernel
        if(model.firstloop==1)
            T = model.index - 1;
        else
            T = options.cnt;
        end
        sigma=KernelOptions.t;

        norm2xt=sum(xt.*xt);

        %% CZ: gradient descent updation
        %%% warning: different algorithm now!
        prob_yt_ft=LogisticProb(-ft_xt*yt);
        %%
        
        tmp=options.eta*yt*(1-prob_yt_ft);
        param = (1-options.eta*options.lamda);
        new_alpha = tmp;
        new_norm = norm2xt;
    end

    %logist
    function prob = LogisticProb(value)
            prob = 1/(1+exp(value));
    end

    %RBF vector
    function k_xt = construct_RBF_Row(norm2xt, norm2X, xtTrainFea, sigma)
        xtx = norm2X + norm2xt - 2*xtTrainFea;
        k_xt = exp(xtx/(-2*sigma^2));
    end

    %class percentage ratio update
    function [class_exist, class_ratio, class_ratio_initial,class_disap,class_rec] = classRatioUpdate(o_class_exist, o_class_ratio, o_class_ratio_initial, current_class_label, disp_threshold)
        current_class_subscript = find(o_class_exist==current_class_label, 1);
        class_count = length(o_class_exist);
        class_disap = [];
        class_rec = 0;

        class_exist = o_class_exist;
        class_ratio = o_class_ratio;
        class_ratio_initial = o_class_ratio_initial;

        %%update for the class that current example belongs to
        if (isempty(current_class_subscript))
            %novel class emergence
            current_class_subscript = class_count + 1;
            class_exist(end+1) = current_class_label;
            class_ratio(end+1) = 0;
            class_ratio_initial(end+1) = 1;
        elseif(class_ratio(current_class_subscript)==0)
            %recurrent class + second example needed for calculate ratio (recurrent or novel)
            if (class_ratio_initial(current_class_subscript)==0)
                %first reveive (recurrent)
                class_rec = current_class_subscript;
                class_ratio_initial(current_class_subscript) = 1;
            else
                %second receive (recurrent or novel)
                new_ratio = 1/class_ratio_initial(current_class_subscript);
                class_ratio(current_class_subscript) = new_ratio;
                class_ratio = class_ratio/sum(class_ratio);
                class_ratio(current_class_subscript) = ratio_decay*class_ratio(current_class_subscript)+1-ratio_decay;
                class_ratio_initial(current_class_subscript) = 0;
            end
        else
            %current exisiting class
            class_ratio(current_class_subscript) = ratio_decay*class_ratio(current_class_subscript)+1-ratio_decay;
        end

        %%update for the other classes
        for j = 1 : class_count
            if (current_class_subscript ~= j)
                %update ratio initial count
                if (class_ratio_initial(j) ~= 0)
                    class_ratio_initial(j) = class_ratio_initial(j)+1;
                end
                %update ratio percentage
                if (class_ratio(j) ~= 0)
                    class_ratio(j) = ratio_decay*class_ratio(j);
                    %set class disappearence
                    if (class_ratio(j) < disp_threshold)
                        class_ratio(j) = 0;
                        class_ratio_initial(j) = 0;
                        class_disap(end+1) = j;
                    end
                end
            end
        end
    end
end