
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

  # given hash of parameters, fulfills their values from a given file
  def load_conf(file, codes = {}, parameters: nil, &project_codes)
    # from config file, assign all the values to internal config object, and validate their correctness
    load file
    if parameters == nil
      @parameters.each do |p,v|
        project_codes&.call(p,v)
        v.value = eval("$#{p}")
      end
    else
      res = parameters
      res.each do |p,v|
        project_codes&.call(p,v)
        v.value = eval("$#{p}")
      end
      return res
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
    iter = 1 
    @parameters.each do |p, v|
      if iteratable?(p)
        size = size * elements_count(v)
        size *= size * v.value if p == :iterate_iterations
      end
   end
    return size
  end

  def parameter_space_dimensions
    iter = 1
    @parameters.each do |parameter, value|
      iter = value.value if parameter == :iterate_iterations
      next if parameter == :iterate_iterations or parameter == :parameter_space_size
      puts "#{parameter}: #{value}" if iteratable?(parameter)
    end
    puts "iterate_iterations: #{iter}"
  end

  def merge(config_object)
    if config_object.is_a?(Hash)
      @parameters.merge!(config_object)
    else
      @parameters.merge!(config_object.parameters)
    end
  end

private

  def elements_count(v)
    (v.value.is_a?(Array) ? v.value.size : 1)
  end

  def iteratable?(parameter)
    raise "unknown parameter '#{parameter}'" unless @paramaters or @parameters[parameter] or @parameters[parameter].checks
    @parameters[parameter].checks[:iteratable]
  end

end

