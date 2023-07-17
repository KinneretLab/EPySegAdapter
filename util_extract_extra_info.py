import os
from tifffile import tifffile
from extra_info_extractor import ExtraInfoExtractor

if __name__ == '__main__':
    # noinspection PyUnresolvedReferences
    extractor = ExtraInfoExtractor()

    # input_paths = [r"Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos1\Cells\AllSegmented",
    #                r"Z:\Analysis\users\Liora\Movie_Analysis\2021_07_26\2021_07_26_pos3\Cells\AllSegmented",
    #                r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos2\Cells\AllSegmented",
    #                r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_06_21_pos4\Cells\AllSegmented",
    #                r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos5\Cells\Inference\2022_06_27_CEE3_CEE5_CEE1E_CEE1E_CEE6",
    #                r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos6\Cells\Inference\2022_07_03_CEE3_CEE5_CEE1E_CEE1E_CEE6"]
    input_paths = [r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\SD1_2021_05_06_pos6\Cells\Segmentation"]
    for input_path in input_paths:
        print(input_path)
        i = 0
        for img_dir in os.listdir(input_path):
            if i == 0:
                i += 1
                continue
            if not os.path.isdir(input_path + "/" + img_dir):
                continue
            # load the segmented image
            extractor.register_image(input_path + "/" + img_dir + "/handCorrection.tif")
            tifffile.imwrite(input_path + "/" + img_dir + "/vertices.tif", extractor.calc_vertices())
            tifffile.imwrite(input_path + "/" + img_dir + "/boundaryPlotter.tif", extractor.calc_bonds())

            i += 1 
            if i % 10 == 1:
                print(i)
