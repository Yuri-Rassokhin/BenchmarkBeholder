
# This class implements common logic for a configuration processor
class GenericConfig < Object

  attr_accessor :parameters

  def value
    @parameters
  end

  def initialize(conf_file)
    @parameters = nil
    @parameter_space_dimensions = nil
    file, line = caller_locations(1,1)[0].absolute_path, caller_locations(1,1)[0].lineno
    raise "(#{file} line #{line}): '#{self.class.name} is a template class, must instantiate through subclasses"
  end

  def load_conf(conf_file, codes = {}, &project_codes)
    # from config file, assign all the values to internal config object, and validate their correctness
    load conf_file
    @parameters.each do |p,v|
      project_codes&.call(p,v)
      v.value = eval("$#{p}")
    end
  end

  def set(parameter, value)
    @parameters[parameter].set!(value)
  end

  def get(parameter)
    raise "unknown parameter '#{parameter}' in config requested" unless parameter and @parameters[parameter]
    return @parameters[parameter].value
  end

  def get?(parameter)
    (parameter and @parameters[parameter]) ? @parameters[parameter].value : nil
  end

#  def get!(*keys)
#    keys.reduce(@parameters) do |current_hash, key|
#      if current_hash.is_a?(Hash) && current_hash.key?(key)
#        current_hash[key]
#      else
#        nil
#      end
#  end

  def parameter_space_size
    size = 1
    @parameters.each do |parameter, value|
      size = size * elements_count(value.value.to_s) if iteratable?(parameter)
   end
    return size
  end

  def parameter_space_dimensions
    @parameter_space_dimensions ||= ""
    @parameters.each do |parameter, value|
      puts parameter if iteratable?(parameter)
      @parameter_space_dimensions += "#{parameter}: #{value}" if iteratable?(parameter)
    end
  end

  def merge(config_object)
    if config_object.is_a?(Hash)
      @parameters.merge!(config_object)
    else
      @parameters.merge!(config_object.parameters)
    end
  end

private

  def elements_count(value)
    value.split(',').reject(&:empty?).count
  end

  def iteratable?(parameter)
    raise "unknown parameter '#{parameter}'" unless @paramaters or @parameters[parameter] or @parameters[parameter].checks
    @parameters[parameter].checks[:iteratable]
  end

end

