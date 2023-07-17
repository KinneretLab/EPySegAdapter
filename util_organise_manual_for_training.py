import os
import shutil
from pathlib import Path


def main():
    epyseg_dir = Path(r"Z:\Analysis\users\Projects\Noam\handCorrectedSegmentation_Jul2023")

    # copy folder/handCorrection.tiff -> out/folder.tiff, folder.tiff -> in/folder.tiff
    (epyseg_dir / 'in').mkdir()
    (epyseg_dir / 'out').mkdir()
    for file_path in epyseg_dir.iterdir():
        if not file_path.is_dir():
            name_no_extension = file_path.name.removesuffix('.tiff').removesuffix('.tif')
            shutil.copyfile(file_path,
                            epyseg_dir / 'in' / (name_no_extension + '.tiff'))
            shutil.copyfile(epyseg_dir / name_no_extension / 'handCorrection.tif',
                            epyseg_dir / 'out' / (name_no_extension + '.tiff'))


if __name__ == '__main__':
    main()
