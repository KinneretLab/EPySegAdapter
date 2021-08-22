function [] = arrangeSegmentedImages(baseDir, NewBaseDir, sigmaVals,isRawEPySeg,planes)
% This function runs over segmentation images saved through TissueAnalyzer
% or EPySeg and sorts them into indicative folders according to their
% output type, naming each image informatively according to the original
% image it is based on. The format of the sorted files is according to what
% is used for final image inference training and activation.
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
                    newSubDir = [NewBaseDir,num2str(j)];
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
end

