class Exampleconfig < GenericConfig

  def initialize(conf_file)
    @parameters = startup_parameters
    @parameters.merge(iterate_parameters)
    load_conf(conf_file)
  end

def startup_parameters
  { }
end

def iterate_parameters
  { }
end

  require_relative 'input_parameters'
  include InputParameters

end
