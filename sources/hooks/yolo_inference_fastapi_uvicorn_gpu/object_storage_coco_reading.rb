class Yolo_inference_fastapi_uvicorn_gpu < Collector

def initialize(config, url, mode, logger, series)
  super(config, url, mode, logger, series)
end

require_relative 'launch'

end

