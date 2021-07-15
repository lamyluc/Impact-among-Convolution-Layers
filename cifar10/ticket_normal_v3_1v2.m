for P=1:5
    P
    %conjunto de dados
    image_train=datastore('C:\Users\Lucas\OneDrive\Ambiente de Trabalho\deep\cifar10\CIFAR-10-images-master\train','IncludeSubfolders',true,'LabelSource','foldernames');
    [train10, val5, test5, big] = splitEachLabel(image_train, 0.3, 0.05, 0.1);
    imds_train10=augmentedImageDatastore([32 32], train10);
    imds_val5=augmentedImageDatastore([32 32], val5);
    imds_test5=augmentedImageDatastore([32 32], test5);
    
    %load peso zero
    load peso_inicial.mat
    
    %Define as camadas iniciais da rede com pesos inicias pré definidos
    layers0 = [
        imageInputLayer([32 32 3],"Name","imageinput")
        convolution2dLayer([7 7],16,"Name","c1",'Padding',[0 0 0 0],'Weights',c1w0,'Bias',c1b0)
        averagePooling2dLayer([2 2],"Name","s2","Stride",[2 2],'Padding',[0 0 0 0])
        tanhLayer
        convolution2dLayer([7 7],32,"Name","c3",'Padding',[0 0 0 0],'Weights',c2w0,'Bias',c2b0)
        averagePooling2dLayer([2 2],"Name","s4","Padding","same","Stride",[2 2])
        convolution2dLayer([7 7],128,"Name","c5","Padding","same",'Weights',c3w0,'Bias',c3b0)
        fullyConnectedLayer(10,"Name","f6",'Weights',c4w0,'Bias',c4b0)
        tanhLayer
        softmaxLayer("Name","softmax")
        classificationLayer("Name","classoutput")
        ];
    %
    % Define as opções de treinamento
    options = trainingOptions('sgdm', ...
        'MaxEpochs',100, ...
        'ValidationData',imds_val5, ...
        'ValidationFrequency',140, ...
        'MiniBatchSize',128,...
        'Verbose',false,...
        'InitialLearnRate',0.0001,...
        'Momentum',0.8,...
        'VerboseFrequency',140,...
        'Verbose',0,...
        'OutputFcn',@(info)stopIfAccuracyNotImproving(info,3));
      
    
    %======================================================
    %============Método 1 INTERATVE PRUNNING===============
    %======================================================
    treinamentos=30;
    porcent_remain=1;
    porcent_remain2=1;
    for i=1:treinamentos
        %Acompanhamento do  treinamento
        i
        
        %prune p% dos parametros criando the mask
        p=0.1;
        p2=0.2;
        %p=0.1^(1/i);
        %p2=0.2^(1/i);
        
        %treinamneto por j epocas definidas nas opções
        if i==1
            [Net,info]=trainNetwork(imds_train10,layers0,options); %rede 100%
            Net_p(i)=Net;
            info_p(i)=info;
            filename=salva(i,info_p(i),porcent_remain,porcent_remain2);
        else
            [Net,info]=trainNetwork(imds_train10,layers,options); %rede n*(1-p)%
            Net_p(i)=Net;
            info_p(i)=info;
            porcent_remain=porcent_remain*(1-p);
            porcent_remain2=porcent_remain2*(1-p2);
            salva(i,info_p(i),porcent_remain,porcent_remain2,filename);
        end
        
        %garante que os pesos já cortados não sejam cortados de novo
        if i==1
        else
            l2b = c1b_aux{i-1}.*Net.Layers(2,1).Bias; %conv1
            l2w = c1w_aux{i-1}.*Net.Layers(2,1).Weights;
            l5b = c2b_aux{i-1}.*Net.Layers(5,1).Bias; %conv1
            l5w = c2w_aux{i-1}.*Net.Layers(5,1).Weights;
            l7b = c3b_aux{i-1}.*Net.Layers(7,1).Bias; %conv1
            l7w = c3w_aux{i-1}.*Net.Layers(7,1).Weights;
            l8b = c4b_aux{i-1}.*Net.Layers(8,1).Bias; %conv1
            l8w = c4w_aux{i-1}.*Net.Layers(8,1).Weights;
        end
        
        %aplica a função de poda correta
        if i==1
            [c1b,dropoutMask1b]=TickAbs(p,Net.Layers(2,1).Bias); %conv1
            [c1w,dropoutMask1w]=TickAbs(p,Net.Layers(2,1).Weights);
            [c2b,dropoutMask2b]=TickAbs(p,Net.Layers(5,1).Bias); %conv2
            [c2w,dropoutMask2w]=TickAbs(p,Net.Layers(5,1).Weights);
            [c3b,dropoutMask3b]=TickAbs(p,Net.Layers(7,1).Bias); %conv3
            [c3w,dropoutMask3w]=TickAbs(p,Net.Layers(7,1).Weights);
            [c4b,dropoutMask4b]=TickAbs(p2,Net.Layers(8,1).Bias); %fc1
            [c4w,dropoutMask4w]=TickAbs(p2,Net.Layers(8,1).Weights);
        else
            [c1b,dropoutMask1b]=Tick_Abs_nonzero(p,l2b); %conv1
            [c1w,dropoutMask1w]=Tick_Abs_nonzero(p,l2w);
            [c2b,dropoutMask2b]=Tick_Abs_nonzero(p,l5b); %conv2
            [c2w,dropoutMask2w]=Tick_Abs_nonzero(p,l5w);
            [c3b,dropoutMask3b]=Tick_Abs_nonzero(p,l7b); %conv3
            [c3w,dropoutMask3w]=Tick_Abs_nonzero(p,l7w);
            [c4b,dropoutMask4b]=Tick_Abs_nonzero(p2,l8b); %fc1
            [c4w,dropoutMask4w]=Tick_Abs_nonzero(p2,l8w);
        end
        
        %maskaras auxiliares
        c1b_aux{i}=dropoutMask1b;
        c1w_aux{i}=dropoutMask1w;
        c2b_aux{i}=dropoutMask2b;
        c2w_aux{i}=dropoutMask2w;
        c3b_aux{i}=dropoutMask3b;
        c3w_aux{i}=dropoutMask3w;
        c4b_aux{i}=dropoutMask4b;
        c4w_aux{i}=dropoutMask4w;
        
        %reset the remain weights to initial, applying the mask
        c1b=c1b0.*dropoutMask1b;
        c1w=c1w0.*dropoutMask1w;
        c2b=c2b0.*dropoutMask2b;
        c2w=c2w0.*dropoutMask2w;
        c3b=c3b0.*dropoutMask3b;
        c3w=c3w0.*dropoutMask3w;
        c4b=c4b0.*dropoutMask4b;
        c4w=c4w0.*dropoutMask4w;
        
        %set the layers with applied mask on initial weights
        layers = [
            imageInputLayer([32 32 3],"Name","imageinput")
            convolution2dLayer([7 7],16,"Name","c1",'Padding',[0 0 0 0],'Weights',c1w,'Bias',c1b)
            averagePooling2dLayer([2 2],"Name","s2","Stride",[2 2],'Padding',[0 0 0 0])
            tanhLayer
            convolution2dLayer([7 7],32,"Name","c3",'Padding',[0 0 0 0],'Weights',c2w,'Bias',c2b)
            averagePooling2dLayer([2 2],"Name","s4","Padding","same","Stride",[2 2])
            convolution2dLayer([7 7],128,"Name","c5","Padding","same",'Weights',c3w,'Bias',c3b)
            fullyConnectedLayer(10,"Name","f6",'Weights',c4w,'Bias',c4b)
            tanhLayer
            softmaxLayer("Name","softmax")
            classificationLayer("Name","classoutput")
            ];    
    end
      
    %porcentagem cortada
    for i=1:treinamentos
        porc_cortado_full{i}=(numel(c4w_aux{i})-nnz(c4w_aux{i}))/(numel(c4w_aux{i}));
        porc_cortado_conv1{i}=(numel(c1w_aux{i})-nnz(c1w_aux{i}))/(numel(c1w_aux{i}));
        porc_cortado_conv2{i}=(numel(c2w_aux{i})-nnz(c2w_aux{i}))/(numel(c2w_aux{i}));
        porc_cortado_conv3{i}=(numel(c3w_aux{i})-nnz(c3w_aux{i}))/(numel(c3w_aux{i}));
        tot=numel(c4w_aux{i})+numel(c1w_aux{i})+numel(c2w_aux{i})+numel(c3w_aux{i});
        zer=(numel(c4w_aux{i})-nnz(c4w_aux{i}))+(numel(c1w_aux{i})-nnz(c1w_aux{i}))+(numel(c2w_aux{i})-nnz(c2w_aux{i}))+(numel(c3w_aux{i})-nnz(c3w_aux{i}));
        porc_final_cortado{i}=(zer)/(tot);
    end
    
    
    arquivo=readmatrix([filename '.xls']);
    save(filename);
    clear  
end
