require './sources/config/generic_config.rb'

class GeneralConfig < GenericConfig

# load general parameters
def initialize(conf_file, project_codes)
  @conf_file = conf_file
  @parameters = general_parameters
  load_conf(conf_file, project_codes) { |p, v| v.checks = { allowed_values: project_codes } if  project_codes and p == :project_code }
end

def delayed_init
  hook = self.get(:series_benchmark)
  input = File.expand_path("../hooks/#{hook}/parameters.rb", __dir__)
  require input
  self.extend(Object.const_get(:Parameters))

  parameters = startup_parameters
  parameters.merge!(iterate_parameters)
  @parameters.merge!(load_conf(@conf_file, parameters: parameters))
end

# first phase of description substituion - here we substitute all the variables from the config file
def description_substitute
  str = self.get(:series_description).gsub(/\#\{([^}]+)\}/) do |match|
    v = match[2..-2]
    if self.get?(v.to_sym)
      self.get(v.to_sym)
    else
      "\#\{" + "#{v}" + "}"
    end
  end
  self.set(:series_description, str)
end

private

def general_parameters
{
    project_code: VStr.new(non_empty: true, comma_separated: false, allowed_values: []),
    project_tier: VStr.new(non_empty: true, comma_separated: false, allowed_values: [ "test", "production" ]),
    series_description: VStr.new(non_empty: true),
    series_benchmark: VStr.new(non_empty: true),
    startup_actor: VStr.new(non_empty: true, comma_separated: false),
    startup_target: VStr.new(non_empty: true),
    iterate_iterations: VNum.new(non_empty: true, natural: true, iteratable: true),
    # How often to fetch data from the application during training, seconds (can be a fraction, 0.1 or greater)
# TODO: THIS MUST BE APPLICATION-SPECIFIC
#    collect_frequency: VNum.new(positive: true, greater: 0.1),
#    collect_grace_period: VNum.new(natural: true, positive: true),
    infra_platform: VStr.new(non_empty: true, allowed_values: [ "oci", "azure" ]),
#    infra_hosts: VStr.new(non_empty: true, comma_separated: true)
#    infra_user: VStr.new(non_empty: true, comma_separated: false),
  }
end

end

