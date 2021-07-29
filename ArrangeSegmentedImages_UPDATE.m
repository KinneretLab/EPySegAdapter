clear all;
addpath(genpath('\\phhydra\data-new\phkinnerets\Lab\CODE\Hydra\'));

% When using EPySeg or Tissue Analyzer for automatic segmentation, it outputs each
% segmented image renamed "epyseg_raw_predict.tif" or "handCorreation.tif" in a seperate new directory 
% named as the original image.

% The following script rearranges these segmented images: it changes each
% image name into its original informative name, removes it from the
% isolated new directory into a new segmentation directory, and deletes the
% directory which was created by EPySeg orTissue Analyzer.

% Notice: this script deletes directories! It does so only if those dirs
% are empty, but still - be careful and check your input carefully.
% More importantly - this script moves images from one directory to another.
% All images, created by any model, are named the same way (based on their
% original movie), so if one decides to move them all into the same
% directory by mistake, the latest will run over the others.
%% 
% carefully change the 2 directories below:
check = input('If you didnt change the directories below, please press 0 and do so. If you did change them according to your needs, please press 1: ');

baseDir =  ['Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos9\Cells\CARE_ensemble\CARE_output\SS_model_sigma']; % Directories of current segmentation images
NewBaseDir =  ['Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos9\Cells\CARE_ensemble\EPySegRaw\']; % New directory for segmentation images
% Sigma values (or sub-names of folders) for different folders containing the
% segmentation output that you would like to run over.
sigmaVals = {'2_0','2_1','2_2','2_3','2_4','2_5','2_6','2_7','2_8','2_9','3_0'};
% If the segmented images are in the raw epyseg format, set the following
% to 1:
isRawEPySeg = 1; 
% Image planes you would like to save from the EPySeg data (out of 7 - see
% EPySeg manual for details):
planes = [1:7];

%% Run over folders, move and rename segmentation images.
if check == 0, disp('***Running session was stopped***'); return, end
parfor k=1:length(sigmaVals)
    thisBaseDir =  [baseDir,sigmaVals{k},'\'];
    subDirName = 'EPySegRaw';
    myResultsDir = ['SS_model_sigma',sigmaVals{k},'_EPySegRaw']; 

        OrigImDir = thisBaseDir;
        cd(OrigImDir);
        DirList = dir();

         for i = 1:length(DirList)

             cd(OrigImDir);
             if DirList(i).isdir==1 && DirList(i).name(1) ~= '.' 
                name = DirList(i).name;
                cd ([OrigImDir, '\', DirList(i).name]);

                if isRawEPySeg ==1
                    thisIm = read3Dstack([[OrigImDir, DirList(i).name, '\'],'epyseg_raw_predict.tif']);
                    for j=1:length(planes)
                    thisImNew = thisIm(:,:,planes(j));
                    thisIm16bit = uint16((thisImNew-min(min(thisImNew)))/(max(max(thisImNew))-min(min(thisImNew)))*(2^16-1));
                    newSubDir = [NewBaseDir,subDirName,'_',num2str(j)];
                    mkdir(newSubDir);
                    NewImDir = [newSubDir,'\',myResultsDir,'_',num2str(j)];
                    mkdir(NewImDir);
                    imwrite(thisIm16bit, [NewImDir,'\',name,'.tif']);
                    end
                    cd (OrigImDir)
                    delete([[OrigImDir, DirList(i).name, '\'],'epyseg_raw_predict.tif']);
                    try rmdir (name), end % remove empty dir
                else
                                
                NewImDir = [NewBaseDir,'\',myResultsDir];
                mkdir(NewImDir);
                status = movefile([[OrigImDir, DirList(i).name, '\'],'handCorrection.tif'], [NewImDir,[name , '.tif']]);
                cd (OrigImDir)
                try rmdir (name), end % remove empty dir 
                end
            end
         end
end
