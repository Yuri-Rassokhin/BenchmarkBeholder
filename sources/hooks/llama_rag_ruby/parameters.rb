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
    startup_question: VStr.new(non_empty: true, comma_separated: false)
  }
end

# ADD YOUR DEFINITIONS OF WORKLOAD-SPECIFIC ITERATABLE PARAMETERS
def iterate_parameters
  {
    iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: false),
    iterate_requests: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
    iterate_tokens: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
    iterate_temperature: VStr.new(non_empty: true, comma_separated: true, positive: true, iteratable: true)
  }
end

# ADD ME: here, define everything that goes to database, in addition to default data
# For instance, OUTPUT_PARAMETERS= "add column collect_inference_time double(20,16) not null, add column iterate_processes int not null"
def database_parameters
  "
    add column collect_processing_time double(20,16) not null,
    add column collect_request_time_ratio double(20,16) not null,
    add column collect_failed_requests int not null,
    add column iterate_requests int not null,
    add column iterate_tokens int not null,
    add column iterate_temperature double(20,16) not null,
    add column startup_question varchar(500) not null,
    add column collect_answer varchar(500) not null
  "
end

end
