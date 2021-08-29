clear all;
addpath(genpath('\\phhydra\data-new\phkinnerets\Lab\CODE\Hydra\'));
addpath(genpath('Z:\Analysis\users\Yonit\MatlabCodes\'));
warning('off', 'MATLAB:MKDIR:DirectoryExists');% this supresses warning of existing directory

%% General Parameters:
% This script performs three processes:
% 1) Rearranging segmentation images after using EPySeg or TissueAnalyzer.
% 2) Creating ensemble images after segmentation and rearrangement for
% final image inference.
% 3) Post processing of all ensemble images for final image inference.
% NOTICE YOU NEED TO SET THE PARAMETERS FOR ALL THREE PARTS.
workDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos9\Cells';
topDir = [workDir,'\CARE_ensemble\']; % Top directory of all images that will be used for inference.
maskDir = [workDir,'\..\Display\Masks']; % Mask directory.
%% Parameters for rearrnagement:
% When using EPySeg or Tissue Analyzer for automatic segmentation, it
% outputs each segmented image renamed "epyseg_raw_predict.tif" or
% "handCorreation.tif" in a seperate new directory named as the original
% image.

% The following script rearranges these segmented images: it changes each
% image name into its original informative name, removes it from the
% isolated new directory into a new segmentation directory, and deletes the
% directory which was created by EPySeg or Tissue Analyzer.

% Notice: this script deletes directories! It does so only if those dirs
% are empty, but still - be careful and check your input carefully. More
% importantly - this script moves images from one directory to another. All
% images, created by any model, are named the same way (based on their
% original movie), so if one decides to move them all into the same
% directory by mistake, the latest will run over the others.

% carefully change the 2 directories below:
baseDir =  [topDir,'\CARE_output\SS_model_sigma']; % Directories of current segmentation images
NewBaseDir =  [topDir,'\EPySegRawTest\']; % New directory for segmentation images
% Sigma values (or sub-names of folders) for different folders containing the
% segmentation output that you would like to run over.
sigmaVals = {'2_0','2_1','2_2','2_3','2_4','2_5','2_6','2_7','2_8','2_9','3_0'};
% If the segmented images are in the raw epyseg format, set the following
% to 1:
isRawEPySeg = 1; 
% Image planes you would like to save from the EPySeg data (out of 7 - see
% EPySeg manual for details):
planes = [1:7];
%% Parameters for ensemble creation:
% If you want to create separate ensembles from multiple image sets, list
% all directories from which you want to create ensembles, and give each a
% name. Standard naming is the date and indication of folder from which
% ensemble is created, e.g. '27July_E3' for EPySeg3, '27July_E5' for
% EPySeg5.
% Directories from which to create ensemble :
dirList = {'\EPySegRaw\3','\EPySegRaw\5'};
ensembleNameList = {'19Aug_E3','19Aug_E5'}; 
mode = 'all'; %"mean", "var", "std" or "all" (default) - what type of images to save

%% Parameters for post-processing ensemble images:
% This includes multiplying by the image mask, normalising, and saving as
% 16bit with .tif ending. Notice here that images are manipulated and
% resaved, so original images will not be kept.

resize = 0; % If you want to resize all images, set to desired pixel size (e.g. [1024, 1024];
inverseFlags = {'EPySegRaw/4','EPySegRaw/5','EPySegRaw/7','19Aug_E5'}; % List of directories of inverse (light background) images. 
% This is important so their mask is applied correctly and maintains a
% light background. Make sure to include also folder of ensemble of inverse
% images. 
%% Rearrange images - run over folders, move and rename segmentation images.
if ~batchStartupOptionUsed
    check = input('If you didnt change the directories below, please press 0 and do so. If you did change them according to your needs, please press 1: ');
else
    check = 1;
end
if check ~=1 , disp('***Running session was stopped***'); return, end

arrangeSegmentedImages(baseDir, NewBaseDir, sigmaVals,isRawEPySeg,planes);
%% Run Ensemble Images
for i=1:length(dirList)
    dirToImages = [topDir,dirList{i}];
    ensembleName = ensembleNameList{i}; % Best to use date or other (short) informative name.
    % Run function to create and save images:
    ensembleImages (mode, dirToImages,topDir,ensembleName)
end
%% Post-process ensemble images:
postProcessEnsemble(topDir,maskDir,inverseFlags,resize)