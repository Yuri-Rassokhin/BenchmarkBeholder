class Yolo_inference_fastapi_uvicorn_gpu < Collector

def initialize(config, url, mode, logger, series, target)
  super(config, url, mode, logger, series, target)
end

require_relative 'launch'

end

