class Exampleconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
    # ADD YOUR DEFINITIONS OF STARTUP AND ITERATABLE PARAMETERS
    iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: true)
    }
    load_conf(conf_file)
  end

end
