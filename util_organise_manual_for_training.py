import os
import re
import shutil
from pathlib import Path
from typing import List


def removesuffix(string: str, suffix_list: List[str]):
    for suffix in suffix_list:
        if string.endswith(suffix):
            string = string[:-len(suffix)]
    return string


def main():
    epyseg_dir = Path(r"Z:\Analysis\users\Noam\TrainingDatasets\epyseg\2021_06_21_pos_2")
    # use this for using all the images in the folder
    # frame_list = []
    # An example for choosing specific frames
    # frame_list = list(range(1, 327)) + list(range(339, 373)) + list(range(379, 401)) + [657, 662, 663]

    frame_list = []

    # -------------------------

    # copy folder/handCorrection.tiff -> out/folder.tiff, folder.tiff -> in/folder.tiff
    if not (epyseg_dir / 'in').exists():
        (epyseg_dir / 'in').mkdir()
    if not (epyseg_dir / 'out').exists():
        (epyseg_dir / 'out').mkdir()
    for file_path in epyseg_dir.iterdir():
        if file_path.is_dir():
            continue
        frame = int(re.search('(\\d+)\\.tif', file_path.name).group(1))
        if len(frame_list) != 0 and frame not in frame_list:
            continue
        name_no_extension = removesuffix(file_path.name, ['.tiff', '.tif'])
        shutil.copyfile(file_path,
                        epyseg_dir / 'in' / (name_no_extension + '.tiff'))
        shutil.copyfile(epyseg_dir / name_no_extension / 'handCorrection.tif',
                        epyseg_dir / 'out' / (name_no_extension + '.tiff'))


if __name__ == '__main__':
    main()
