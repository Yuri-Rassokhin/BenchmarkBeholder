
class Yolo_inference_fastapi_uvicorn_gpuconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      startup_target_application: VStr.new(non_empty: true),
      iterate_processes: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
      iterate_requests: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true)
    }
    load_conf(conf_file)
  end

end

