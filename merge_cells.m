newFiles = 'Z:\\Analysis\\users\\Projects\\Noam\Workshop\\timelapse\\Cells\\CellDB_direct\\summaries';
oldFiles = 'Z:\\Analysis\\users\\Projects\\Noam\Workshop\\timelapse\\Cells\\CellDB_all\\summaries';

saveLocation = "Z:\\Analysis\\users\\Projects\\Noam\\Workshop\\timelapse\\Cells\\compare_cells\\";

subDirs = dir(newFiles);
subDirs = subDirs(~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));


for i = 1:length(subDirs)
    subDirectory = subDirs(i);
    % get all the images
    onlyCare = imread(fullfile(oldFiles, subDirectory.name));
    fullCell = imread(fullfile(subDirectory.folder, subDirectory.name));

    imgSize = size(onlyCare, 1);
    fullImgCropped = imcrop(fullCell, [imgSize + 1 0 imgSize - 1 imgSize]);
    trueFullImg = fullImgCropped(:,:,2) + 0.5 * fullImgCropped(:,:,3);
    careImgCropped = imcrop(onlyCare, [imgSize + 1 0 imgSize - 1 imgSize]);
    trueCareImg = careImgCropped(:,:,2) + 0.5 * careImgCropped(:,:,3);

    fullCareImg = sum(careImgCropped,3);
    fullFullImg = sum(fullImgCropped,3);

    bounds = imbinarize(fullImgCropped, 0.9);
    newBounds = bounds(:,:,1) & bounds(:,:,2) & bounds(:,:,3);

    combinedImage = cat(3, trueCareImg, newBounds * 255, trueFullImg);
    imwrite(combinedImage, saveLocation + subDirectory.name);
end