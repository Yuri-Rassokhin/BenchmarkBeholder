
class Detectron2TrainingConfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      startup_solver_initial_lr_per_gpu: VNum.new(non_empty: true, positive: true),
      startup_solver_iterations: VNum.new(natural: true),
      startup_dataset_size: VNum.new(natural: true),
      startup_solver_number_of_epochs: VNum.new(natural: true),
      startup_app_flags: VStr.new,

      iterate_number_of_gpus: VNum.new(natural: true, iteratable: true),
      iterate_images_batch_per_gpu: VNum.new(natural: true, iteratable: true),
      iterate_dataloader_threads_per_gpu: VNum.new(natural: true, iteratable: true)
    }
    load_conf(conf_file)
  end

end

