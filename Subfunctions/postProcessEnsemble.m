function [] = postProcessEnsemble(topDir,maskDir,inverseFlags,resize)
% This function is used for post-processing ensemble images for the final
% image infrerence NN. The steps include multiplication by image mask, and
% image normalizatoin.

% Create full list of images in topDir, and read all masks from maskDir:
cd(topDir);
files = dir([topDir,'\**\*.tif*']);
cd(maskDir);
maskFiles = dir('*.tif*');
allMasks =read3DstackDir(maskDir);
disp(['number of files:',num2str(length(files))])
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
end

