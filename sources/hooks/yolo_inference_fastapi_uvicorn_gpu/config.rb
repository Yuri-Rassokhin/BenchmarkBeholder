
class Object_storage_coco_readingconfig < GenericConfig

  def initialize(conf_file)
    @parameters = {
      iterate_processes: VNum.new(non_empty: true, comma_separated: true, natural: true, iteratable: true),
      iterate_requests: VNum.new(non_empty: true, comma_separated: true, natural: true, iteratable: true)
    }
    load_conf(conf_file)
  end

end

