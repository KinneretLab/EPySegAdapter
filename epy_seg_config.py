import os.path
from pathlib import Path
from typing import Dict, Hashable, Any

import yaml


class EPySegConfig:
    """
    Reads the data from config.yml so that it can be used within the script.
    This class also handles template conversions and file-path expansions like relative notations.
    Basically, any configuration settings should be read from here.
    """
    def __init__(self):
        self.input_dir: str = ''
        self.pretraining_model: str = ''
        self.ta_output_mode: bool = True
        self.tile_width: int = 256
        self.tile_height: int = 256
        self.tile_overlap: int = 32
        self.misc_args: Dict[Hashable, Any] = {}
        self.refined_mode: bool = False

    def load(self, rel_path: str) -> None:
        """
        Loads the data present in a configuration file into memory and parses it into useful variables.
        :param rel_path: the relative path from the script directory to the configuration file.
        """
        with open(rel_path, 'r') as stream:
            raw = yaml.safe_load(stream)

            # the work directory is a prefix for other paths. For this, we add a tailing \
            work_dir: str = raw['work_dir']
            if not work_dir.endswith('/'):
                work_dir += '/'

            # basic data reading of various variables
            self.pretraining_model = raw['pretraining_model']
            self.ta_output_mode = raw['ta_output_mode']
            self.tile_height = raw['tile_height']
            self.tile_width = raw['tile_width']
            self.tile_overlap = raw['tile_overlap']
            self.refined_mode = raw['refined_mode']

            # the input directory is a bit more clever, and changes based on whether we are in refined mode or not.
            if self.refined_mode:
                self.input_dir = self._get_refined_input_dir(self.to_absolute(work_dir, raw['refined_input_dir']))
            else:
                self.input_dir = self.to_absolute(work_dir, raw['raw_input_dir'])

            # bad code on EPy-Seg's side forces this.
            self.misc_args['default_output_tile_width'] = self.tile_width
            self.misc_args['default_output_tile_height'] = self.tile_height

            self.misc_args = {**self.misc_args, **raw['misc_args']}

    @staticmethod
    def to_absolute(work_dir: str, path: str) -> str:
        """
        converts the path, whatever form it may be in, into an absolute path
        :param work_dir: the working directory from which to mark the relative path
        :param path: the path to convert. May be absolute or relative to work_dir
        :return: an absolute path leading to the target specified by path.
        """
        return path if os.path.isabs(path) else work_dir + path

    @staticmethod
    def _get_refined_input_dir(path: str) -> str:
        # Final image can generate the result in a sub-directory with a changing date.
        # This lists all potential sub-directories and chooses the one created last.
        # If not applicable, this returns the argument.
        candidates = [candidate for candidate in Path(path).iterdir() if candidate.is_dir() and
                      len([child for child in candidate.iterdir() if child.is_dir()]) == 0]
        if len(candidates) == 0:
            return path
        else:
            candidates.sort(key=lambda directory: directory.stat().st_mtime_ns)
            return str(candidates[0])
