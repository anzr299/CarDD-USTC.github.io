clear; close all; clc;
%import xlswrite;
%import mat2cell;

%set your dataset path and saliency map result path.
%dataset = 'CarDD_v2';
%gtPath = 'E:\wangxinkuang\data\CarDD_v2_SOD\CarDD-TE\CarDD-TE-Mask';
%salPath = 'E:\wangxinkuang\result\CarDD_v2_SOD\PoolNet\PoolNet_epoch_48';
%xlsxPath = 'E:\wangxinkuang\result\CarDD_v2_SOD\PoolNet\metrics.xlsx';
%csvPath = 'E:\wangxinkuang\result\CarDD_v2_SOD\PoolNet\metrics.csv';

%dataset = 'CarDD';
%class = 'tire-flat';
%gtPath = ['D:\wangxinkuang\data\CarDD-classwise-subset\CarDD-' class '\test2017'];
%salPath = ['E:\wangxinkuang\result\SGL-KRN-classwise\' class];
%xlsxPath = ['E:\wangxinkuang\result\CarDD_v1_SOD\class-wise\' class];
%csvPath = ['E:\wangxinkuang\result\CarDD_v1_SOD\class-wise\' class];
%if ~isfolder(xlsxPath)
%    mkdir(xlsxPath);
%end
%if ~isfolder(csvPath)
%    mkdir(csvPath);
%end
%xlsxPath = [xlsxPath '\metrics.xlsx'];
%csvPath = [csvPath '\metrics.csv'];



dataset = 'CarDD';
model = 'CSNet';
gtPath = 'E:\wangxinkuang\data\CarDD-SOD\CarDD\CarDD-TE\CarDD-TE-Mask';
salPath = 'E:\wangxinkuang\result\CSNet';
xlsxPath = ['E:\wangxinkuang\result\CarDD_v1_SOD\total\' model];
csvPath = ['E:\wangxinkuang\result\CarDD_v1_SOD\total\' model];
if ~isfolder(xlsxPath)
    mkdir(xlsxPath);
end
if ~isfolder(csvPath)
    mkdir(csvPath);
end
xlsxPath = [xlsxPath '\metrics.xlsx'];
csvPath = [csvPath '\metrics.csv'];




%obtain the total number of image (ground-truth)
imgFiles = dir(gtPath);
imgNUM = length(imgFiles)-2;

%evaluation score initilization.
Smeasure=zeros(1,imgNUM);
Emeasure=zeros(1,imgNUM);
Fmeasure=zeros(1,imgNUM);
MAE=zeros(1,imgNUM);
F_wm=zeros(1,imgNUM);
names=repmat("",1,imgNUM);

tic;
for i = 1:imgNUM
    
    fprintf('Evaluating: %d/%d\n',i,imgNUM);
    
    name =  imgFiles(i+2).name;
    %name = name(:,3:10);
    names(i) = name;
    
    %load gt
    gt = imread([gtPath '\' name]);
    
    if numel(size(gt))>2
        gt = rgb2gray(gt);
    end
    if ~islogical(gt)
        gt = gt(:,:,1) > 128;
    end
    
    %load salency
    sal  = imread([salPath '\' name]);
    
    %check size
    if size(sal, 1) ~= size(gt, 1) || size(sal, 2) ~= size(gt, 2)
        sal = imresize(sal,size(gt));
        imwrite(sal,[salPath name]);
        fprintf('Error occurs in the path: %s!!!\n', [salPath name]);
       
    end
    
    sal = im2double(sal(:,:,1));
    
    %normalize sal to [0, 1]
    sal = reshape(mapminmax(sal(:)',0,1),size(sal));
    
    Smeasure(i) = StructureMeasure(sal,logical(gt));
    temp = Fmeasure_calu(sal,double(gt),size(gt)); % Using the 2 times of average of sal map as the threshold.
    Fmeasure(i) = temp(3);
   
    MAE(i) = mean2(abs(double(logical(gt)) - sal));
    F_wm(i) = WFb(sal, logical(gt));
    
    %You can change the method of binarization method. As an example, here just use adaptive threshold.
    %threshold =  2* mean(sal(:)) ;
    threshold =  mean(sal(:)) ;
    %fprintf('%f   ',threshold);
    if ( threshold > 1 )
        threshold = 1;
    end
    Bi_sal = zeros(size(sal));
    Bi_sal(sal>threshold)=1;
    Emeasure(i) = Enhancedmeasure(Bi_sal,gt);
 
    %fprintf('%f\n',Emeasure(i));
    
    
    
end

toc;

Sm = mean2(Smeasure);
Fm = mean2(Fmeasure);
Em = mean2(Emeasure);
mae = mean2(MAE);
F_wm_mean = mean2(F_wm);

Smeasure = [Smeasure Sm];
Emeasure = [Emeasure Em];
Fmeasure = [Fmeasure Fm];
MAE = [MAE mae];
F_wm = [F_wm F_wm_mean];
names = [names "Avg"];

fprintf('(%s Dataset)Emeasure: %.3f; Smeasure %.3f; weighted_F: %.3f; Fmeasure %.3f; MAE: %.3f.\n',dataset, Em, Sm, F_wm_mean, Fm, mae);

title = ["file_name" "Fmeasure" "weighted_F" "Smeasure" "Emeasure" "MAE"];
data = [names' Fmeasure' F_wm' Smeasure' Emeasure' MAE'];
data_title = [title;data];
writematrix(data_title, xlsxPath);
writematrix(data_title, csvPath);

