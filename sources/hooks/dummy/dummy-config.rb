
class Dummyconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
    }
    load_conf(conf_file)
  end

end

