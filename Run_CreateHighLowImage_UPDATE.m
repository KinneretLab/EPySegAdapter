addpath(genpath('\\phhydra\data-new\phkinnerets\home\lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydrab\Analysis\users\Projects\ShaiAndShir\matlab codes'));

% Choose 1 or 0 if you want to use the segmentation mask to multiply low
% images for training - so only parts of the image that contain a signal in the high images are included (seemed to work better overall).
flag_mask = input ('enter 0 or 1: flag_mask = ');

forInference = 1; % Set to 1 if need high images for inference training, or zero (default) for high images used for CARE training. 
% The difference is that for inference, we don't multiply by the original
% image, just by a constant gaussian. For CARE training we mulitply
% gaussian-blurred skeleton by original image intensities.

% Sigma values for gaussian blur
sigmaVals = [2:0.1:3];

% Input path (top directory and list of subdirectories where original
% images + manual segmentation masks are saved. 
topMainDir='\\phhydra\phhydraB\Analysis\users\Yonit\Movie_Analysis\DefectLibrary\';
mainDirList = {'2020_09_01_24hr_set1\Cells\TrainingData2\', ...
              };
          
% Path for saving output
b_path = '\\phhydra\phhydraB\Analysis\users\Projects\ShaiAndShir\cellSegmetationSS\20X\Inference_Yonit\GroundTruth_inference_2\';
input(['b_path is: ',b_path,'. Check it before proceeding. Continue?']);
NewLowDir = [b_path,'LOW'];
mkdir(NewLowDir);

% Create input directory list
for i=1:length(mainDirList)
    mainInDirList{i}=[topMainDir,mainDirList{i}];
end

%% Run over input folders, create and save high and low images
for j = 1:length(mainDirList)
    
    cd(mainInDirList{j});
    DirList = dir();

    for i = 1:length(DirList)
        if DirList(i).isdir==0
            
            cd(mainInDirList{j});    
            image = imread(DirList(i).name);
            name_end = find(DirList(i).name == '.');
            name = DirList(i).name(1:(name_end-1));
            %% crop according to an inner mask
            if flag_mask == 1
                mask = imread([mainInDirList{j},'..\..\Display\Masks\',DirList(i).name]);
                SE = strel('sphere',16);
                %%% this parameter (16) determines the level of edges-ignoring since
                %%% morphologic operation reduces the mask size %%%
                heavyMask = logical(imerode(mask,SE));
                masked_image = image;
                masked_image(~heavyMask)= 0;
                %%
                cd(NewLowDir);
                imwrite(uint16(masked_image), [name,'.tif']); %imwrite(image, [name,'.tif']);
            else
                cd(NewLowDir);
                imwrite(uint16(image), [name,'.tif']);
            end
            
            Sigma_gauss = round(sigmaVals,1);
            HighPath = [b_path,'High'];
            for ind = 1:length(Sigma_gauss)
                strSigma = num2str(Sigma_gauss(ind));
                if ~(strSigma=='.')
                    strSigma = [strSigma, '.0'];
                end
                strSigma(strSigma=='.')='_';
                
                NewHighDir = [HighPath,'_sigma',strSigma,'\'];
                if ~exist(NewHighDir, 'dir'), mkdir(NewHighDir), end
                
                cd([mainInDirList{j},name]);
                handCorrection = imread('handCorrection.tif');
                if forInference==0
                    if flag_mask == 1
                        HighIm = CreateHighImage_ss(handCorrection, image, Sigma_gauss(ind), heavyMask);% CreateHighImage_ss(handCorrection, image, Sigma_gauss(ind));
                    else
                        HighIm = CreateHighImage_ss(handCorrection, image, Sigma_gauss(ind));
                    end
                    
                else
                    if flag_mask == 1
                        HighIm = CreateHighImage_inference(handCorrection, image, Sigma_gauss(ind), heavyMask);
                    else
                        HighIm = CreateHighImage_inference(handCorrection, image, Sigma_gauss(ind));
                    end
                    
                end
                cd(NewHighDir);
                imwrite(HighIm, [name,'.tif']);
            end
        end
    end
end