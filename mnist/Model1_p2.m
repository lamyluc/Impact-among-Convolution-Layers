%------------------------------------------------------------------------
%------------------------------------------------------------------------
%SET UP A EXPERIMENTAL TABLE

L=[ 1 1 1 1 1 1 1 1 1 1 1;
    1 1 1 1 1 2 2 2 2 2 2;
    1 1 2 2 2 1 1 1 2 2 2;
    1 2 1 2 2 1 2 2 1 1 2;
    1 2 2 1 2 2 1 2 1 2 1;
    1 2 2 2 1 2 2 1 2 1 1;
    2 1 2 2 1 1 2 2 1 2 1;
    2 1 2 1 2 2 2 1 1 1 2;
    2 1 1 2 2 2 1 2 2 1 1;
    2 2 2 1 1 1 1 2 2 1 2;
    2 2 1 2 1 2 1 1 1 2 2;
    2 2 1 1 2 1 2 1 2 2 1;
    ];

[L_i,L_j]=size(L);
nivel=max(L);

%Replace hyperparameters, line=factor, column=levels
%Set the hyperparameters non-numeric last
nivel_par=[3 7; %fs1
           16 32; %nf1
           3 7; %fs2
           32 64; %nf2
           3 7; %fs3
           64 128; %nf3
           0.001 0.0001; %inital learn rate
           0.8 0.9; %momentum
           128 256; %mini batch size
           9 99 %activation function
           ];
       [n_p_i,n_p_j]=size(nivel_par);

%Replace the hyperparametrs values in experimental table
for i=1:nivel
    for j=1:(min(L_j,n_p_i))
        aux=L(:,j)==i;
        M(aux,j)=nivel_par(j,i);
    end
end
M;

%Replace the hyperparametrs values in experimental table
[f_i,f_j]=find(M==9);
[f2_i,f2_j]=find(M==99);
[f3_i,f3_j]=find(M==999);

%format transformation
M2=num2cell(M);

%Replace the hyperparametrs values in experimental table
for i=1:numel(f_i)
    M2{f_i(i),f_j(i)}='reluLayer';
end
for i=1:numel(f2_i)
    M2{f2_i(i),f2_j(i)}='tanhLayer';
end
M2;

%Experimental table
[M_i,M_j]=size(M);

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%load Data
path1=''; %path for training dataset 
path2=''; %path for test dataset 
image_train=datastore(path1,'IncludeSubfolders',true,'LabelSource','foldernames');
image_test=datastore(path2,'IncludeSubfolders',true,'LabelSource','foldernames');
imds=augmentedImageDatastore([32 32], image_train);
imdsValidation=augmentedImageDatastore([32 32], image_test);


%variaveis para plots
TrainingLoss={};
ValidationLoss={};
TrainingAccuracy={};
ValidationAccuracy={};
Tempo=[];

%TRAIN NETWORK
for i=1:L_i
    i
    %Get the hyperparameters
    Param=M2(i,:);
    
     %Set Layers
    act_str=cell2mat(Param(10));
    switch act_str
        case 'reluLayer'
            act=reluLayer;
        case 'tanhLayer'
            act=tanhLayer;
        case 'eluLayer'
            act=eluLayer;
    end
    
    layers = [
        imageInputLayer([32 32 1],"Name","imageinput")
        convolution2dLayer([cell2mat(Param(1)) cell2mat(Param(1))],cell2mat(Param(2)),"Name","c1",'Padding',[0 0 0 0])
        averagePooling2dLayer([2 2],"Name","s2","Stride",[2 2],'Padding',[0 0 0 0])
        act
        convolution2dLayer([cell2mat(Param(3)) cell2mat(Param(3))],cell2mat(Param(4)),"Name","c3",'Padding',[0 0 0 0])
        averagePooling2dLayer([2 2],"Name","s4","Padding","same","Stride",[2 2])
        convolution2dLayer([cell2mat(Param(5)) cell2mat(Param(5))],cell2mat(Param(6)),"Name","c5","Padding","same")
        fullyConnectedLayer(10,"Name","f6")
        act
        softmaxLayer("Name","softmax")
        classificationLayer("Name","classoutput")];
    
    %Set Options
    options = trainingOptions('sgdm', ...
        'MaxEpochs',30, ...
        'ValidationData',imdsValidation, ...
        'ValidationFrequency',floor((60000)/(cell2mat(Param(9)))), ...
        'MiniBatchSize',cell2mat(Param(9)),...
        'Verbose',false,...
        'InitialLearnRate',cell2mat(Param(7)),...
        'Momentum',cell2mat(Param(8)),...
        'OutputFcn',@(info)stopIfAccuracyNotImproving(info,5));
    
    try
        %Training network
        tic;
        [Net,info]=trainNetwork(imds,layers,options);
        toc;
        t=toc;
        
        %Save results
        filename='Result';
        local=strcat('A',num2str(i));
        escrita=[i Param info.TrainingAccuracy(end) info.TrainingLoss(end) info.FinalValidationAccuracy info.FinalValidationLoss];
         path3=''; %path for write  the results
        xlswrite([path 3 '\Result.xls'],escrita,1,local)
        
        %Save results of all trainings
        TrainingLoss=[TrainingLoss; info.TrainingLoss];
        ValidationLoss=[ValidationLoss; info.ValidationLoss];
        TrainingAccuracy=[TrainingAccuracy;info.TrainingAccuracy];
        ValidationAccuracy=[ValidationAccuracy; info.ValidationAccuracy];
        Tempo=[Tempo;t];
        
         %Save results of network
        aux10=strcat('Run_',num2str(i));
        mkdir (aux10)
        aux11=strcat(path3,aux10,'\Net.mat');
        save (aux11,'Net')
        aux12=strcat(path3,aux10,'\info.mat');
        save (aux12,'info')
        
    catch exception
        %salvar resultado experimental
        filename='Result';
        local=strcat('A',num2str(i));
        escrita=[i Param];
        xlswrite([path3 '\Result.xls'],escrita,1,local)
        
        %Salvar informa????es de todos os treinamentos
        TrainingLoss=[TrainingLoss; NaN];
        ValidationLoss=[ValidationLoss; NaN];
        TrainingAccuracy=[TrainingAccuracy; NaN];
        ValidationAccuracy=[ValidationAccuracy; NaN];
        Tempo=[Tempo;NaN];
        
        %Salvar resultado rede
        aux10=strcat('Run_',num2str(i));
        mkdir (aux10)
        %exception = MException.last;
        msgText = getReport(exception)
        aux11=strcat(path3,aux10,'\msgText.txt');
        save (aux11,'msgText')
    end
    
end

%salvar variaveis
TrainingLoss=completa(TrainingLoss);
save TrainingLoss
ValidationLoss=completa(ValidationLoss);
save ValidationLoss
TrainingAccuracy=completa(TrainingAccuracy);
save TrainingAccuracy
ValidationAccuracy=completa(ValidationAccuracy);
save ValidationAccuracy
save Tempo

%Opr????es extras
function stop = stopIfAccuracyNotImproving(info,N)

%Possives altera????es
% Epoch	Current epoch number
% Iteration	Current iteration number
% TimeSinceStart	Time in seconds since the start of training
% TrainingLoss	Current mini-batch loss
% ValidationLoss	Loss on the validation data
% BaseLearnRate	Current base learning rate
% TrainingAccuracy	Accuracy on the current mini-batch (classification networks)
% TrainingRMSE	RMSE on the current mini-batch (regression networks)
% ValidationAccuracy	Accuracy on the validation data (classification networks)
% ValidationRMSE	RMSE on the validation data (regression networks)
% State Current training state, with a possible value of "start", "iteration", or "done"


% Tracking variables
%bestValAccuracy - best accuracy value
%valLag - number of not improving
stop = false;
persistent bestValAccuracy
persistent valLag

% Clear the variables when training starts.
if info.State == "start"
    bestValAccuracy = 0;
    valLag = 0;
    
elseif ~isempty(info.ValidationLoss)
    
    % Compare the current validation accuracy to the best accuracy so far,
    % and either set the best accuracy to the current accuracy, or increase
    % the number of validations for which there has not been an improvement.
    if info.ValidationAccuracy > bestValAccuracy
        valLag = 0;
        bestValAccuracy = info.ValidationAccuracy;
    else
        valLag = valLag + 1;
    end
    
    % If the validation lag is at least N, that is, the validation accuracy
    % has not improved for at least N validations, then return true and
    % stop training.
    if valLag >= N
        stop = true;
    end
    
end
end
