module Parameters

# Parameter can be either VNum (for a single numeric value) or VStr (non-numeric values or lists of values)
# Parameters should have data validation, the following validation apply.
#
# For a single numeric parameter:
# VNum.new(natural: true, positive: true, negative: true, range: 1..13, greater: 5, lower: 10)
#
# For multiple values or non-numeric value:
# VStr.new(comma_separated: true, natural: true, non_empty: true, allowed_values: [ "val1", "val2" ])
# 
# You can apply any combination of such validations.

# ADD DEFINITIONS OF WORKLOAD-SPECIFIC STARTUP PARAMETERS
def startup_parameters
  {
      startup_model: VStr.new(non_empty: true, allowed_values: [ "yolov8n", "yolov8s", "yolov8m", "yolov8l", "yolov8x", "yolov5n", "yolov5s", "yolov5m", "yolov5l", "yolov5x" ]),
      startup_dataset: VStr.new(non_empty: true),
      startup_epochs: VStr.new(non_empty: true, natural: true),
      startup_image_size: VStr.new(non_empty: true, natural: true),
      startup_batch: VStr.new(non_empty: true, positive: true),
      startup_device: VStr.new(non_empty: true, allowed_values: [ "cuda:0", "cuda", "cpu" ] )
  }
end

# ADD YOUR DEFINITIONS OF WORKLOAD-SPECIFIC ITERATABLE PARAMETERS
def iterate_parameters
  {
    iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: false)
  }
end

# ADD ME: here, define everything that goes to database, in addition to default data
# For instance, "add column collect_inference_time double(20,16) not null, add column iterate_processes int not null"
def database_parameters
  "
    add column collect_training_time double(20,16) not null,
    add column startup_model varchar(100) not null,
    add column startup_dataset varchar(100) not null,
    add column startup_epochs int not null,
    add column startup_image_size int not null,
    add column startup_batch double(20,16) not null,
    add column startup_device varchar(10) not null
  "
end

end
