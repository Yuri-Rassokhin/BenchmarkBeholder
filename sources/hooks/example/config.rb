class Exampleconfig < GenericConfig

  def initialize(conf_file)
    @parameters = startup_parameters
    @parameters.merge!(iterate_parameters)
    load_conf(conf_file)
  end

private

require_relative 'input_parameters'
include InputParameters

def startup_parameters
  super
end

def iterate_parameters
  super
end

end
