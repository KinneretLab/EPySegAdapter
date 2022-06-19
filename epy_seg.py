from pathlib import Path
from typing import List

import numpy as np
import scipy.ndimage
import tifffile
import yaml
from epyseg.deeplearning.deepl import EZDeepLearning
import os

from epy_seg_config import EPySegConfig


def find_vertices(input_path: str) -> None:
    """
    finds all the vertices of the cortices in a segmented image and saves them as an image in a corresponding folder.
    :param input_path: the absolute path to the segmented image
    """
    for img_dir in os.listdir(input_path):
        if not os.path.isdir(input_path + "/" + img_dir):
            continue
        # load the segmented image
        seg_img = tifffile.imread(input_path + "/" + img_dir + "/handCorrection.tif")[:, :]
        seg_img[seg_img > 0] = 1  # turn image to binary

        img_size = len(seg_img)
        mask = np.zeros((img_size, img_size)).astype(np.uint8)
        for i in range(0, img_size):
            for j in range(0, img_size):
                if seg_img[i, j] == 1:
                    # to check if a point is a vertex, we load its 3x3 pixel area and
                    # split the black pixels into groups.
                    # If there are at least 3 separate groups, the candidate must be a vertex.
                    kernel = np.zeros((3, 3))
                    kernel[i == 0:3 - (i == img_size - 1), j == 0:3 - (j == img_size - 1)] += \
                        seg_img[max(i - 1, 0):min(i + 1, img_size - 1) + 1, max(j - 1, 0):min(j + 1, img_size - 1) + 1]
                    labels = scipy.ndimage.measurements.label(np.logical_not(kernel), [[0, 1, 0], [1, 1, 1], [0, 1, 0]])
                    if np.max(labels[0]) >= 3:
                        mask[i, j] = 255

        tifffile.imwrite(input_path + "/" + img_dir + "/vertices.tif", mask)  # save image


def main() -> None:
    """
    This script is responsible for running EPy-Seg, which segments a noise filtered image to
    find the edges of cortices in a cell image.
    """
    cfg = EPySegConfig()
    try:
        cfg.load('cfg/config.yml')
    except yaml.YAMLError as e:
        print('\033[91mCould not load configuration file. Error: \033[0m' + str(e))
        return

    dir_list = get_latest(cfg.input_dir) if cfg.refined_mode else os.listdir(cfg.input_dir)
    for folder in dir_list:
        input_path = cfg.input_dir + '/' + folder
        # magic.

        # raw code for predict
        deep_ta = EZDeepLearning()
        deep_ta.load_or_build(architecture='Linknet', backbone='vgg16', activation='sigmoid', classes=7,
                              pretraining=cfg.pretraining_model, model=cfg.model)

        deep_ta.get_loaded_model_params()
        deep_ta.summary()

        input_shape = deep_ta.get_inputs_shape()
        output_shape = deep_ta.get_outputs_shape()

        predict_generator = deep_ta.get_predict_generator(
            inputs=[input_path], input_shape=input_shape,
            output_shape=output_shape,
            default_input_tile_height=cfg.tile_height, default_input_tile_width=cfg.tile_width,
            tile_height_overlap=cfg.tile_overlap, tile_width_overlap=cfg.tile_overlap,
            clip_by_frequency=None, **cfg.misc_args)

        if not cfg.ta_output_mode:
            predict_output_folder = os.path.join(cfg.input_dir, 'predict')
        else:
            predict_output_folder = 'TA_mode'

        post_process_algorithm = 'default' if cfg.refined_mode else None

        deep_ta.predict(predict_generator, output_shape, predict_output_folder=predict_output_folder, batch_size=1,
                        post_process_algorithm=post_process_algorithm, **cfg.misc_args)

        if cfg.refined_mode:
            find_vertices(input_path)


def get_latest(path: str) -> List[str]:
    # Final image can generate the result in a sub-directory with a changing date.
    # This lists all potential sub-directories and chooses the one created last.
    # If not applicable, this returns the argument.
    candidates = [candidate for candidate in Path(path).iterdir() if candidate.is_dir() and
                  len([child for child in candidate.iterdir() if child.is_dir()]) == 0]
    if len(candidates) == 0:
        return [Path(path).name]
    else:
        candidates.sort(key=lambda directory: directory.stat().st_mtime_ns)
        return [candidates[0].name]


if __name__ == '__main__':
    main()
