function [] = EEOF(file_data,file_result,outname,a,b,c,e,disp_threshold)
% file_data: the path to data file, containing x and y
% file_result: store the experiment results
% outname: store the time cost
% a: eta
% b: lambda
% c: t
% e: decay factor
% disp_threshold: disappearance threshold for EEOF

% Parameters
M = 10; % number of ensemble for each Ensemble OVA
options.eta = a;
options.lamda = b;
KernelOptions.t = c;
ratio_decay = e;
options.cnt = 5000; % maximum number of kernel vectors in KLR

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

% read & classify example, update model
t_count=0;
tic;
while t_count<example_count
    t_count = t_count+1;

    real_label = y(t_count);
    new_example = x(:,t_count);
    real_index = find(class_exist==real_label);
    
    % classify examples
    classifier_count = length(ensemble);
    ft_array = [];
    if(classifier_count>0)
        classify_result = zeros(1, classifier_count);

        % Initialize ensemble OVA for emerging class
        ft_array = zeros(M, classifier_count);

        for i = 1 : classifier_count
            if(ensemble(i).active == 0)
                classify_result(i) = 0;
                ft_array(:,i) = NaN;
            else
                % classification results on each ensemble OVA model
                sum_classify_result = 0;
                for idx_submodel = 1:M
                    [tmp_classify_result, tmp_ft_array] = OnlineKLRClassify(new_example,ensemble(i).model(idx_submodel));
                    sum_classify_result = sum_classify_result+ tmp_classify_result;
                    ft_array(idx_submodel, i) = tmp_ft_array;
                end
                classify_result(i) = sum_classify_result/M;
            end
        end
        [max_probability, predic_subscript] = max(classify_result);
        prediction = class_exist(predic_subscript);

        % confidence-triggered fallback mode
        if (max_probability) <= 0.5
            have_change = 0;
            for idx_cls = 1:numel(classify_result)
                if classify_result(idx_cls) == 0
                    sum_classify_result = 0;
                    for idx_submodel = 1:M
                        [tmp_classify_result, tmp_ft_array] = OnlineKLRClassify(new_example,ensemble(idx_cls).model(idx_submodel));
                        sum_classify_result = sum_classify_result+ tmp_classify_result;
                        ft_array(idx_submodel, idx_cls) = tmp_ft_array;
                    end
                    classify_result(idx_cls) = sum_classify_result/M;
                    
                    have_change = 1;
                end
            end

            if have_change
                [max_probability, predic_subscript] = max(classify_result);
                prediction = class_exist(predic_subscript);
            end
        end
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

    % update ensemble OVAs
    real_subscript = find(class_exist==real_label);
    if(real_subscript == length(ensemble)+1)
        ensemble(real_subscript).model = [];
        ensemble(real_subscript).active = 1;
        for idx_submodel = 1:M
            ensemble(real_subscript).model(idx_submodel).currentAlpha = zeros(1,options.cnt);
            ensemble(real_subscript).model(idx_submodel).norm2X = zeros(1,options.cnt);
            ensemble(real_subscript).model(idx_submodel).trainFea = zeros(dimension,options.cnt);
            ensemble(real_subscript).model(idx_submodel).index = 1;
            ensemble(real_subscript).model(idx_submodel).firstloop = 1;   
        end
       
        ft_array(1:M,end+1) = 0;
    end
    classifier_count = length(ensemble);

    % model adaptation process
    for i = 1 : classifier_count
        clf_class = class_exist(i);

        % initialize loss weights for each model in every ensemble OVA
        K = poissrnd(1, 1, M);

        if(i == real_subscript)
            label_tmp = 1; % positive label 
        else
            label_tmp = -1; % negative label

            ratio_tmp = class_ratio(i);
            select_ratio = ratio_tmp/(1-ratio_tmp);            
            K = poissrnd(select_ratio, 1, M);
        end

        for idx_submodel = 1:M

            update_time = K(idx_submodel);
            if update_time >= 1
                if(isnan(ft_array(idx_submodel,i)))
                    [~,ft_array(idx_submodel, i)] = OnlineKLRClassify(new_example,ensemble(i).model(idx_submodel));
                end

                [param,new_alpha,new_norm] = OnlineKLRUpdate(new_example,label_tmp,ft_array(idx_submodel, i),ensemble(i).model(idx_submodel));
                ensemble(i).model(idx_submodel).currentAlpha = param*ensemble(i).model(idx_submodel).currentAlpha;
                ensemble(i).model(idx_submodel).currentAlpha(ensemble(i).model(idx_submodel).index) = update_time * new_alpha;
                ensemble(i).model(idx_submodel).norm2X(ensemble(i).model(idx_submodel).index) = new_norm;
                ensemble(i).model(idx_submodel).trainFea(:,ensemble(i).model(idx_submodel).index) = new_example;
                ensemble(i).model(idx_submodel).index = ensemble(i).model(idx_submodel).index+1;
                if(ensemble(i).model(idx_submodel).index>options.cnt)
                    ensemble(i).model(idx_submodel).index = 1;
                    ensemble(i).model(idx_submodel).firstloop = 0;
                end
            end
        end
    end
end
time = toc;
fclose(fid_result);
save(outname,'time');

    % classify of KLR
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

    % update of KLR
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

        prob_yt_ft=LogisticProb(-ft_xt*yt);

        tmp=options.eta*yt*(1-prob_yt_ft);
        param = (1-options.eta*options.lamda);
        new_alpha = tmp;
        new_norm = norm2xt;
    end

    % logist function in KLR
    function prob = LogisticProb(value)
            prob = 1/(1+exp(value));
    end

    % RBF vector in KLR
    function k_xt = construct_RBF_Row(norm2xt, norm2X, xtTrainFea, sigma)
        xtx = norm2X + norm2xt - 2*xtTrainFea;
        k_xt = exp(xtx/(-2*sigma^2));
    end

    % class percentage ratio update
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