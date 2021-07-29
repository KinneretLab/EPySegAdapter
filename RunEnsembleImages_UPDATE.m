%% RunEnsembleInages
clear all;
addpath(genpath('\\phhydra\data-new\phkinnerets\Lab\CODE\Hydra\'));
addpath(genpath('\\phhydra\phhydraB\Analysis\users\Yonit\MatlabCodes'));

topDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos9\Cells\CARE_ensemble\'; % Top directory of all images that will be used for inference.
maskDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos9\Display\Masks\'; % Mask directory.
%% Part I - create ensemble images (look at ensembleImages function for further explanations and documentation.
% If you want to create separate ensembles from multiple image sets, list
% all directories from which you want to create ensembles, and give each a
% name. Standard naming is the date and indication of folder from which
% ensemble is created, e.g. '27July_E3' for EPySeg3, '27July_E5' for
% EPySeg5.
% Directories from which to create ensemble :
dirList = {'\EPySegRaw\3','\EPySegRaw\5'};
ensembleNameList = {'27July_E3','27July_E5'}; 
mode = 'all'; %"mean", "var", "std" or "all" (default) - what type of images to save

for i=1:length(dirList)
    dirToImages = [topDir,dirList{i}];
    ensembleName = ensembleNameList{i}; % Best to use date or other (short) informative name.
    % Run function to create and save images:
    ensembleImages (mode, dirToImages,topDir,ensembleName)
end

%% Part II - Post-processing all ensemble images
% This includes multiplying by the image mask, normalising, and saving as
% 16bit with .tif ending. Notice here that images are manipulated and
% resaved, so original images will not be kept.

resize = 0; % If you want to resize all images, set to desired pixel size (e.g. [1024, 1024];
inverseFlags = {'EPySegRaw/4','EPySegRaw/5','EPySegRaw/7','27July_E5'}; % List of directories of inverse (light background) images. 
% This is important so their mask is applied correctly and maintains a
% light background. Make sure to include also folder of ensemble of inverse
% images. 

% Create full list of images in topDir, and read all masks from maskDir:
cd(topDir);
files = dir([topDir,'\**\*.tif*']);
cd(maskDir);
maskFiles = dir('*.tif*');
allMasks =read3DstackDir(maskDir);
length(files)

% Run over all files and post-process according to image format and type
% (normal vs. inverse)
parfor i=1:length(files)
    i
    cd(files(i).folder)
    thisIm = imread(files(i).name);
    if length(size(thisIm))==3
        thisImG = double(rgb2gray(thisIm));
    else
        thisImG = double(thisIm);
    end
    name_end = find(files(i).name == '.');
    fileName = files(i).name(1:(name_end-1));
    imNum = find(contains({maskFiles.name}, [fileName,'.']));
    
    % Check if image is an inverse image, and if so set value outside of
    % mask to be max value rather than zero.
    if contains(files(i).folder, inverseFlags)
        thisMask = double(im2bw(allMasks(:,:,imNum)));
        if resize~=0
            thisImG = imresize(thisImG,resize);
            thisMask = imresize(thisMask,resize,'nearest');
        end
        thisMin = min(min(thisImG));
        thisImG(thisImG<thisMin)=thisMin;
        thisMax = max(max(thisImG));
        thisImNorm = ((thisImG-thisMin)/(thisMax-thisMin))*(2^16-1);
        thisMask = double(im2bw(allMasks(:,:,imNum)));
        thisImNorm(thisMask==0)=max(max(thisImNorm));
        thisImMasked = thisImNorm;
        cd(files(i).folder); delete(files(i).name);
        imwrite(uint16(thisImMasked),[fileName,'.tif']); % save masked image
    else
        thisMask = double(im2bw(allMasks(:,:,imNum)));
         if resize~=0
            thisImG = imresize(thisImG,resize);
            thisMask = imresize(thisMask,resize,'nearest');
        end
        [N,edges] = histcounts(thisImG,256);
        thisMin = mean([edges(find(N==max(N))),edges(find(N==max(N))+1)]);
        thisImG(thisImG<thisMin)=thisMin;
        thisMax = max(max(thisImG));
        thisImNorm = ((thisImG-thisMin)/(thisMax-thisMin))*(2^16-1);
        thisMask = double(im2bw(allMasks(:,:,imNum)));
        thisImNorm(thisMask==0)=0;
        thisImMasked = thisImNorm;
        cd(files(i).folder); delete(files(i).name);
        imwrite(uint16(thisImMasked),[fileName,'.tif']); % save masked image
    end
end