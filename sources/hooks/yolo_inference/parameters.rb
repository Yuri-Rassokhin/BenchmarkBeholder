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
      startup_target_application: VStr.new(non_empty: true),
      startup_device: VStr.new(non_empty: true, allowed_values: [ "0", "1", "2", "3", "4", "5", "6", "7", "cuda", "cpu" ] )
  }
end

# ADD YOUR DEFINITIONS OF WORKLOAD-SPECIFIC ITERATABLE PARAMETERS
def iterate_parameters
  {
      iterate_processes: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
      iterate_requests: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
      iterate_images: VStr.new(non_empty: true, comma_separated: true, iteratable: true)
  }
end

# ADD ME: here, define everything that goes to database, in addition to default data
# For instance, "add column collect_inference_time double(20,16) not null, add column iterate_processes int not null"
def database_parameters
  "
    add column collect_inference_time double(20,16) not null,
    add column collect_error varchar(100),
    add column iterate_processes int not null,
    add column iterate_requests int not null,
    add column iterate_device varchar(20) not null,
    add column collect_image_resolution varchar(20) not null,
    add column collect_image_format varchar(20) not null,
    add column collect_image_metadata varchar(500) not null,
    add column startup_target_app_command varchar(500) not null,
    add column startup_target_app_code varchar(8192)
  "
end

end
