
class Object_storage_coco_readingconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      startup_namespace: VStr.new(non_empty: true),
      # iterate_operations: VStr.new(non_empty: true, comma_separated: true, allowed_values: ["read"], iteratable: true)
    }
    load_conf(conf_file)
  end

end

