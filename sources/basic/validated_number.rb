class VNum
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

  def +(other)
    ensure_initialized!
    VNum.new(@checks).tap do |vn|
      vn.value = @value + extract_value(other)
    end
  end

  def -(other)
    ensure_initialized!
    VNum.new(@checks).tap do |vn|
      vn.value = @value - extract_value(other)
    end
  end

  def *(other)
    ensure_initialized!
    VNum.new(@checks).tap do |vn|
      vn.value = @value * extract_value(other)
    end
  end

  def /(other)
    ensure_initialized!
    VNum.new(@checks).tap do |vn|
      vn.value = @value / extract_value(other)
    end
  end

  def to_s
    ensure_initialized!
    @value.to_s
  end

  def validate!(value)
    unless value.is_a?(Numeric)
      raise ArgumentError, "Value must be a numeric type"
    end

    if @checks[:natural] && (!value.is_a?(Integer) || value < 0)
      raise ArgumentError, "Value must be a natural number (non-negative integer)"
    end

    if @checks[:negative] && value >= 0
      raise ArgumentError, "Value must be a negative number"
    end

    if @checks[:positive] && value <= 0
      raise ArgumentError, "Value must be a positive number"
    end

    if @checks[:range] && !@checks[:range].include?(value)
      raise ArgumentError, "Value must be within the range #{@checks[:range]}"
    end

    if @checks[:greater] && ! (value > @checks[:greater])
      raise ArgumentError, "Value must be greater than #{@checks[:greater]}"
    end

    if @checks[:lower] && ! (value < @checks[:lower])
      raise ArgumentError, "Value must be lower than #{@checks[:lower]}"
    end

  end

  private

  def extract_value(other)
    other.is_a?(VNum) ? other.value : other
  end

  def ensure_initialized!
    raise "Value not initialized" if @value.nil?
  end
end

# Example usage
#begin
#  natural = VNum.new(natural: true)
#  puts natural + 3  # This will raise an error
#rescue => e
#  puts e.message  # Output: "Value not initialized"
#end

#begin
#  natural.value = 5
#  puts natural + 3  # Output: 8
#rescue => e
#  puts e.message
#end

#begin
#  negative = VNum.new(negative: true)
#  puts negative - 2  # This will raise an error
#rescue => e
#  puts e.message  # Output: "Value not initialized"
#end

#begin
#  positive = VNum.new(positive: true)
#  positive.value = 7.5
#  puts positive * 2  # Output: 15.0
#rescue => e
#  puts e.message
#end

#begin
#  range_num = VNum.new(range: 5..15)
#  range_num.value = 10
#  puts range_num / 2  # Output: 5.0
#rescue => e
#  puts e.message
#end

# Combined checks
#begin
#  combined = VNum.new(natural: true, range: 0..10)
#  combined.value = 7
#  puts combined + 2  # Output: 9
#rescue => e
#  puts e.message
#end

# Validate on assignment
#begin
#  combined.value = 8  # Valid assignment
#  puts combined  # Output: 8
#rescue => e
#  puts e.message
#end

# This will raise an error
#begin
#  combined.value = 11  # Error: Value must be within the range 0..10
#rescue => e
#  puts e.message
#end

# This will also raise an error
#begin
#  natural.value = -1  # Error: Value must be a natural number (non-negative integer)
#rescue => e
#  puts e.message
#end

