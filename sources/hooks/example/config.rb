class Exampleconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
    # ADD YOUR DEFINITIONS OF STARTUP AND ITERATABLE PARAMETERS
    }
    load_conf(conf_file)
  end

end
