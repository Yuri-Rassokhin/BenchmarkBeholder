
class Ddconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: true, allowed_values: [ "mq-deadline", "bfq", "kyber", "none"]),
      # how many bytes to consume at a time
      iterate_sizes: VStr.new(non_empty: true, natural: true, comma_separated: true, iteratable: true),
      # list of operations
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read", "write"], iteratable: true),
    }
    load_conf(conf_file)
  end

end

