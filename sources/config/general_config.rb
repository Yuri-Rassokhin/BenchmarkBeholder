
# This class implements common parameters of any benchmark, and common semantics
# This class to be inherited by benchmar-specific class
class GeneralConfig < GenericConfig

require './sources/config/generic_config.rb'

def initialize(conf_file, project_codes)
  @parameters = {

    project_description: VStr.new(non_empty: true, comma_separated: false),
    project_code: VStr.new(non_empty: true, comma_separated: false, allowed_values: []),
    project_tier: VStr.new(non_empty: true, comma_separated: false, allowed_values: [ "test", "production" ]),

    series_description: VStr.new(non_empty: true),
    series_benchmark: VStr.new(non_empty: true),
    series_owner_name: VStr.new(non_empty: true, comma_separated: false),
    series_owner_email: VStr.new(non_empty: true, comma_separated: false),

    startup_actor: VStr.new(non_empty: true, comma_separated: false),
    startup_target: VStr.new(non_empty: true),

    iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: true, allowed_values: [ "mq-deadline", "bfq", "kyber", "none"]),

    # How many times to repeat every individual invocation (to accumulate statistics)
    iterate_iterations: VNum.new(non_empty: true, natural: true, iteratable: true),
    # How often to fetch data from the application during training, seconds (can be a fraction, 0.1 or greater)
# TODO: THIS MUST BE APPLICATION-SPECIFIC
#    collect_frequency: VNum.new(positive: true, greater: 0.1),
#    collect_grace_period: VNum.new(natural: true, positive: true),

    infra_platform: VStr.new(non_empty: true, allowed_values: [ "oci" ]),
    infra_hosts: VStr.new(non_empty: true, comma_separated: true),
    infra_user: VStr.new(non_empty: true, comma_separated: false),
  }
  load_conf(conf_file, project_codes) { |p, v| v.checks = { allowed_values: project_codes } if  project_codes and p == :project_code }
end

end

