
class Ddconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      startup_target: VStr.new(non_empty: true),
      startup_type: VStr.new(non_empty: true, allowed_values: ["file", "device", "bucket", "object"]),
      startup_namespace: VStr.new(non_empty: true),
      iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read", "write"], iteratable: true)
    }
    load_conf(conf_file)
  end

end

