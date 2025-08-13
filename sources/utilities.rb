module Utilities
  module_function

MULTIPLIERS = {
  'K' => 1024,
  'M' => 1024**2,
  'G' => 1024**3,
  'T' => 1024**4,
  'P' => 1024**5,
  'E' => 1024**6
}.freeze

# takes JSON and unscale all numbers of a kind '2845G', '4343K', etc, case-insensitive
def json_unscale(logger, obj)
  case obj
  when Hash
    obj.transform_values { |v| json_unscale(logger, v) }
  when Array
    obj.map { |v| json_unscale(logger, v) }
  else
    parsed = self.number_unscale(logger, obj)
    parsed.nil? ? obj : parsed
  end
end

# converts given value between scaling units: K/k, M/m, G/g, T/t, P/p.
def convert_units(logger, value, from: , to: , precision: )
  bytes = units_to_bytes(logger, value, from: from, precision: precision)
  bytes_to_units(logger, bytes, to: to, precision: precision)
end

private

def self.number_unscale(logger, input)
  return input if input.is_a?(Integer)

  unless input.is_a?(String)
    logger.error "string '#{input}' received when integer with scaling suffix expected"
    return nil
  end

  if input =~ /\A(\d+(?:\.\d+)?)([KMGTP])\z/i
    ($1.to_f * MULTIPLIERS[$2.upcase]).to_i
  elsif input =~ /\A\d+\z/
    input.to_i
  else
    nil
  end
end

def self.units_to_bytes(logger, value, from: , precision: )
  scale = from[0..1].gsub(' ', '').downcase # take first two symbols to determine scale: KB, MB, GB, TB, PB
  case scale
  when "kb"
    res = value * 1024
  when "mb"
    res = value * 1024 * 1024
  when "gb"
    res = value * 1024 * 1024 * 1024
  when "tb"
    res = value * 1024 * 1024 * 1024 * 1024
  when "pb"
    res = value * 1024 * 1024 * 1024 * 1024 * 1024
  else
    logger.error "unsupported unit #{from}"
  end
  res.round(precision)
end

def self.bytes_to_units(logger, value, to: , precision: )
  scale = to[0..1].gsub(' ', '').downcase # take first two symbols to determine scale: KB, MB, GB, TB, PB
  case scale
  when "kb"
    res = value / 1024
  when "mb"
    res = value / 1024 / 1024
  when "gb"
    res = value / 1024 / 1024 / 1024
  when "tb"
    res = value / 1024 / 1024 / 1024 / 1024
  when "pb"
    res = value / 1024 / 1024 / 1024 / 1024 / 1024
  else
    logger.error "unsupported units #{units}"
  end
  res.round(precision)
end

end
