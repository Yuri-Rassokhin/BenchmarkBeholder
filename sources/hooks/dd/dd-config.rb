
class Ddconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      # NOTE: benchmark-specific configuration parameter
      iterate_sizes: VStr.new(non_empty: true, natural: true, comma_separated: true, iteratable: true),
      # NOTE: benchmark-specific configuration parameter
      startup_media: VStr.new(non_empty: true),
      # NOTE: benchmark-specific list of operations
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read", "write"], iteratable: true),
    }
    load_conf(conf_file)
  end

end

