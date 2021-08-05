import os.path
from typing import Dict, Hashable, Any

import yaml


class EPySegConfig:
    def __init__(self):
        self.input_dir: str = ''
        self.pretraining_model: str = ''
        self.ta_output_mode: bool = True
        self.tile_width: int = 256
        self.tile_height: int = 256
        self.tile_overlap: int = 32
        self.misc_args: Dict[Hashable, Any] = {}
        self.refined_mode: bool = False

    def load(self, rel_path: str):
        with open(rel_path, 'r') as stream:
            raw = yaml.safe_load(stream)

            work_dir: str = raw['work_dir']
            if not work_dir.endswith('/'):
                work_dir += '/'

            self.pretraining_model = raw['pretraining_model']
            self.ta_output_mode = raw['ta_output_mode']
            self.tile_height = raw['tile_height']
            self.tile_width = raw['tile_width']
            self.tile_overlap = raw['tile_overlap']
            self.refined_mode = raw['refined_mode']

            self.input_dir = self.to_absolute(work_dir, raw['input_dir'])

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
