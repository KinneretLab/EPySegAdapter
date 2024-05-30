newSegmentationDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos4\Cells\Segmentation';
oldSegmentationDir = 'Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos4\Cells\Segmentation_Old';

saveLocation = "Z:\Analysis\users\Noam\Movie_Analysis\Yonit_2024_06_21_pos4\compare";

subDirs = dir(newSegmentationDir);
subDirs = subDirs([subDirs.isdir] & ~strcmp({subDirs.name},'.') & ~strcmp({subDirs.name},'..'));

for subDirectory = subDirs
    % get all the images
    oldSegmentationImage = imread(fullfile(oldSegmentationDir, subDirectory.name, 'handCorrection.tif'));
    rawImage = imread(fullfile(subDirectory.folder, subDirectory.name + ".tiff")) / 256;
    newSegmentationImage = imread(fullfile(subDirectory.folder, subDirectory.name, 'handCorrection.tif'));

    combinedImage = cat(3, oldSegmentationImage(:,:,1), rawImage(:,:,1), newSegmentationImage(:,:,1));
    imwrite(combinedImage, saveLocation + "/" + subDirectory.name + ".tif");
end