class VStr
  attr_reader :value, :checks

  def initialize(checks = {})
    @checks = checks
    @value = nil  # Start with a nil value to signify uninitialized state
  end

  def size
    @value.size
  end

  def value=(new_value)
    if @checks[:comma_separated] && @checks[:natural]
      # If the value is expected to be a comma-separated list of VNum objects
      elements = new_value.split(',').map(&:strip)
      vnums = elements.map do |element|
        vnum = VNum.new(natural: @checks[:natural])
        vnum.value = element.to_i  # Assuming the list contains integers
        vnum
      end
      validate!(vnums)
      @value = vnums
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
        vs.value = combined_value.join(',')
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
      value.each do |vnum|
        unless vnum.is_a?(VNum)
          raise ArgumentError, "All elements must be of type VNum"
        end
        vnum.ensure_initialized!
      end
    else
      unless value.is_a?(String)
        raise ArgumentError, "Value must be a string"
      end

      if @checks[:non_empty] && value.strip.empty?
        raise ArgumentError, "Value cannot be empty"
      end

      if @checks[:comma_separated]
        unless (value.include?(',') or value == "" or value.split.size == 1)
          raise ArgumentError, "Value must be a comma-separated list"
        end

        if @checks[:allowed_values]
          invalid_values = value.split(',').map(&:strip) - @checks[:allowed_values]
          unless invalid_values.empty?
            raise ArgumentError, "Value contains invalid entries: #{invalid_values.join(', ')}"
          end
        end
      elsif @checks[:allowed_values]
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

# Example usage
#begin
  # Create a VStr object that expects a comma-separated list of natural numbers
#  vstr = VStr.new(non_empty: true, comma_separated: true, natural: true)

  # Assign a valid comma-separated list of natural numbers
#  vstr.value = "1, 2, 3, 4"
#  puts vstr  # Output: "1, 2, 3, 4"

  # Attempt to assign an invalid value (not a natural number)
#  vstr.value = "1, -2, 3, 4"  # This will raise an error
#rescue => e
#  puts e.message  # Output: "Value must be a natural number (non-negative integer)"
#end


