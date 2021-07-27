function [] = ensembleImages (mode, dirToImages,topDir, resultDir)
% mode:         str. 
%               this function computes mean, several kinds of variances, 
%               and std. the choosing mode determines what images will be
%               saved. options are: "mean", "var", "std" or "all".
%               It also creates consent_level_images - see line 83.
% resultDir:    str. folder's name where the outputs will be saved in
% dirToImages:  str. directory where the predicted images are in.
% Hierarchy:
% dirToImages
% ---- sigma_1
% ------------img_1
% ------------img_2
% ------------ ...
% ------------img_m
% ---- sigma_2
% ---- ...
% ---- sigma_m

    % read tiff images
    cd(dirToImages);
    allImgs =       struct2table(dir('**/*.tif'));
    imgsNames =     table2array(unique(allImgs(:,1)));
    allDirs =       ls;
    allDirs =       allDirs(allDirs(:,1) ~= '.',:);
    
    mkdir([topDir,'\compData\ensembles\' ,resultDir]);
    for imgind = 1:length(imgsNames) % each image
        cd(dirToImages);
        img =               imgsNames{imgind};
        sumImage =          double(imread(fullfile(allDirs(1,:), img)));
        bin_im =            zeros(size(sumImage));
        if size(sumImage,3) ~= 1, sumImage = sumImage(:,:,1); end
        varTensor =         zeros(size(sumImage,1), size(sumImage,2) ,length(allDirs(:,1)) );
        varTensor(:,:,1) =  sumImage; %initial varTensor with the first img
        for dirind = 2:length(allDirs(:,1)) % all models
            rgbImage =              imread(fullfile(allDirs(dirind,:), img));
            if size(rgbImage,3) ~= 1, rgbImage = rgbImage(:,:,1); end
            varTensor(:,:,dirind) = rgbImage;
            sumImage =              sumImage + double(rgbImage); 
            bin_im =                bin_im + imbinarize(rgbImage/min(maxk(rgbImage(:),1000)));
        end
        
        %% compute mean, variacne, std
        meanImage =     sumImage / length(allDirs(:,1));
        normSumImage =  sumImage / max(sumImage(:));
        
        varImage =      var(varTensor,0,3); %3rd dim = models dim
%         % explicit calculation of the variance: E [(X-E[X])^2]
%         meanTensorDup = double(reshape(repmat (meanImage, 1, size(varTensor,3) ),size(varTensor)));
%         varImage =      mean ( (varTensor - meanTensorDup).^2 ,3);
        stdImage =      std(varTensor,0,3);
        %% post normalized var
        postNormVar = varImage./max(max(varImage));
        %% compute mean, variacne, std - over normalized images
        meanImageNorm =         meanImage./max(max(meanImage));
        varTensorNorm =         varTensor./max(varTensor,[],3); 
        varImageNormPre =       var(varTensorNorm,0,3); 
        stdImageNormPre =       std(varTensorNorm,0,3);
              
         %% save the outcome
        cd ([topDir,'\compData\ensembles\' ,resultDir])
        
        if mode == "all" || mode == "mean"
            mkdir([resultDir,'_mean']);
            imwrite(uint16(meanImage), fullfile([resultDir,'_mean'], img), 'tif');
        end
        if mode == "all" || mode == "var"
            mkdir([resultDir, '_var']);
            imwrite(uint16(varImage), fullfile([resultDir, '_var'],img), 'tif');
            mkdir([resultDir,'_preNormVar']);
            imwrite(uint16(varImageNormPre), fullfile([resultDir, '_preNormVar'],img), 'tif');
            mkdir([resultDir,'_postNormVar']);
            imwrite(uint16(postNormVar), fullfile([resultDir, '_postNormVar'],img), 'tif');
        end   
        if mode == "all" || mode == "std"
            mkdir([resultDir, '_std']);
            imwrite(uint16(stdImage), fullfile([resultDir, '_std'],img), 'tif');
        end
       
    %% analyze
%     cd (['..','\compData\ensembles\' ,resultDir])
    consent_level_range = 5:10;
    for consent_ind = 1:length(consent_level_range)
        consent_level = consent_level_range(consent_ind);
       % bin_im_consent =
       % 255*uint8(bwskel(imbinarize(uint8(bin_im>=consent_level)))); %skeletonized
        bin_im_consent = 255*uint8(imbinarize(uint8(bin_im>=consent_level))); % Pixel-wise agreement, no skeletonization.
        mkdir([resultDir,'sum_models_bin_consent', num2str(consent_level)]);
        imwrite(bin_im_consent, fullfile([resultDir,'sum_models_bin_consent', num2str(consent_level)], img), 'tif');
    end


    end
    
end

% dirToImages = '\\phhydra\phhydraB\Analysis\users\Lital\PhD\PycharmProjects\care\CellsSegmentation\SS_PredictedData'