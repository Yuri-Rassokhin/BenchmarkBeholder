class VStr
  attr_reader :value, :checks

  def initialize(checks = {})
    @checks = checks
    @value = nil  # Start with a nil value to signify uninitialized state
  end

  # NOTE: use cautiosly, this method doesn't apply value checks
  def set!(value)
    @value = value
  end

  def size
    @value.size
  end

  def value=(new_value)
    if @checks[:comma_separated]
      # Split the string by commas and strip whitespace
      elements = new_value.is_a?(String) ? new_value.split(',').map(&:strip) : new_value

      if @checks[:natural]
        # Convert elements to VNum objects if natural numbers are expected
        vnums = elements.map do |element|
          vnum = VNum.new(natural: @checks[:natural])
          vnum.value = element.to_i  # Assuming the list contains integers
          vnum
        end
        validate!(vnums)
        @value = vnums
      else
        # If it's a list of strings, validate each string and store them as an array
        validate!(elements)
        @value = elements
      end
    else
      validate!(new_value)
      @value = new_value
    end
  end

  def checks=(new_checks)
    @checks.merge!(new_checks)  # Merge new checks with existing ones
    delayed_validate! if @value
  end

  def +(other)
    ensure_initialized!
    if @value.is_a?(Array)
      combined_value = @value + extract_value(other)
      VStr.new(@checks).tap do |vs|
        vs.value = combined_value.join(', ')
      end
    else
      VStr.new(@checks).tap do |vs|
        vs.value = @value + extract_value(other)
      end
    end
  end

  def to_s
    ensure_initialized!
    @value.is_a?(Array) ? @value.map(&:to_s).join(', ') : @value.to_s
  end

  private

  def delayed_validate!
    validate!(@value)
  end

  def validate!(value)
    if value.is_a?(Array)
      if @checks[:natural]
        value.each do |vnum|
          unless vnum.is_a?(VNum)
            raise ArgumentError, "All elements must be of type VNum"
          end
          vnum.send(:ensure_initialized!)
        end
      else
        value.each do |v|
          unless v.is_a?(String)
            raise ArgumentError, "All elements must be strings"
          end

          if @checks[:non_empty] && v.strip.empty?
            raise ArgumentError, "Value cannot be empty"
          end

          if @checks[:allowed_values]
            unless @checks[:allowed_values].include?(v)
              raise ArgumentError, "Value contains invalid entries: #{v}"
            end
          end
        end
      end
    else
      unless value.is_a?(String)
        raise ArgumentError, "Value must be a string"
      end

      if @checks[:non_empty] && value.strip.empty?
        raise ArgumentError, "Value cannot be empty"
      end

      if @checks[:allowed_values]
        unless @checks[:allowed_values].include?(value)
          raise ArgumentError, "Value contains invalid entries: #{value}"
        end
      end
    end
  end

  def extract_value(other)
    if other.is_a?(VStr)
      other.value
    else
      other
    end
  end

  def ensure_initialized!
    raise "Value not initialized" if @value.nil?
  end
end

