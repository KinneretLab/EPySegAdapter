import yaml
from epyseg.deeplearning.deepl import EZDeepLearning
import os

from epy_seg_config import EPySegConfig


def main():
    cfg = EPySegConfig()
    try:
        cfg.load('cfg/config.yml')
    except yaml.YAMLError as e:
        print('\033[91mCould not load configuration file. Error: \033[0m' + str(e))
        return

    for folder in os.listdir(cfg.input_dir):
        input_path = cfg.input_dir + '/' + folder

        # raw code for predict
        deepTA = EZDeepLearning()
        deepTA.load_or_build(architecture='Linknet', backbone='vgg16', activation='sigmoid', classes=7,
                             pretraining=cfg.pretraining_model)

        deepTA.get_loaded_model_params()
        deepTA.summary()

        input_shape = deepTA.get_inputs_shape()
        output_shape = deepTA.get_outputs_shape()

        predict_generator = deepTA.get_predict_generator(
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

        deepTA.predict(predict_generator, output_shape, predict_output_folder=predict_output_folder, batch_size=1,
                       post_process_algorithm=post_process_algorithm, **cfg.misc_args)


if __name__ == '__main__':
    main()
