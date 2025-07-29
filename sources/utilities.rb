module Utilities
  module_function

def convert_units(logger, value, from: , to: , precision: )
  bytes = units_to_bytes(logger, value, from: from, precision: precision)
  bytes_to_units(logger, bytes, to: to, precision: precision)
end

private

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
