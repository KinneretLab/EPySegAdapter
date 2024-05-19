from tifffile import tifffile
import numpy as np
import os
from scipy.ndimage import binary_dilation

if __name__ == '__main__':
    input_path = r"Z:\Analysis\users\Yonit\Movie_Analysis\Labeled_cells\2021_05_06_pos6\Cells\Segmentation"
    for img_dir in os.listdir(input_path):
        if not os.path.isdir(input_path + "/" + img_dir):
            continue
        print(img_dir)

        if not os.path.exists(input_path + "/" + img_dir + "/cell_identity.tif"):
            continue
        cell_identity = tifffile.imread(input_path + "/" + img_dir + "/cell_identity.tif")

        dims = 2
        size = max(cell_identity.shape)
        if cell_identity.ndim == 3:
            dims = 3
            if cell_identity.shape[0] == 3:
                cell_identity = np.amax(cell_identity, 0)
            else:
                cell_identity = np.amax(cell_identity, 2)
        cell_identity[0, :] = cell_identity[:, 0] = cell_identity[:, size - 1] = cell_identity[size - 1, :] = 0
        cell_identity[cell_identity == 1] = 0
        cell_identity[cell_identity > 0] = 1

        segmentation = binary_dilation(cell_identity) - cell_identity
        if dims == 3:
            segmentation = 255 * np.stack([segmentation, segmentation, segmentation])

        tifffile.imwrite(input_path + "/" + img_dir + "/handCorrection.tif", segmentation)