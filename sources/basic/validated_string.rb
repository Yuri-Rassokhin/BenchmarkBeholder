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
    validate!(new_value)
    @value = new_value
  end

  def checks=(new_checks)
    @checks.merge!(new_checks)  # Merge new checks with existing ones
    delayed_validate! if @value
  end

  def +(other)
    ensure_initialized!
    VStr.new(@checks).tap do |vs|
      vs.value = @value + extract_value(other)
    end
  end

  def to_s
    ensure_initialized!
    @value.to_s
  end

  private

  def delayed_validate!
    validate!(@value)
  end

  def validate!(value)
    unless value.is_a?(String)
      raise ArgumentError, "Value must be a string"
    end

    if @checks[:non_empty] && value.strip.empty?
      raise ArgumentError, "Value cannot be empty"
    end

    if @checks[:comma_separated]
      # comma-separated list can be, in particular, an empty string or a single word
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

  def extract_value(other)
    other.is_a?(VStr) ? other.value : other
  end

  def ensure_initialized!
    raise "Value not initialized" if @value.nil?
  end
end

# Example usage
#begin
  # Create an object with initial validations
#  project_code = VStr.new(non_empty: true)
#  project_code.value = "code1"
#  puts project_code  # Output: "code1"

  # Add more validations later, without wiping out the initial validation
#  project_code.checks = { allowed_values: ["code1", "code2", "code3"], comma_separated: false }

  # Try assigning a valid value
#  project_code.value = "code2"
#  puts project_code  # Output: "code2"

  # Try assigning an invalid value
#  project_code.value = "code4"  # This will raise an error: Value contains invalid entries: code4
#rescue => e
#  puts e.message
#end

#begin
  # Further extend the validations
#  project_code.checks = { allowed_values: ["code1", "code2", "code3", "code4"] }

  # Now this will work
#  project_code.value = "code4"
#  puts project_code  # Output: "code4"
#rescue => e
#  puts e.message
#end

#begin
  # Assign a value that fails the non_empty check
#  project_code.value = ""  # This will raise an error: Value cannot be empty
#rescue => e
#  puts e.message
#end

