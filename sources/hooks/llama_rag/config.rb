
class Llama_ragconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      iterate_requests: VStr.new(non_empty: true, comma_separated: true, natural: true, iteratable: true)
    }
    load_conf(conf_file)
  end

end

