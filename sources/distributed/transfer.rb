
def transfer(value, depth = 0)
  indent = '  ' * depth  # Two spaces per depth level

  case value

  when String, Numeric, Symbol, true, false, nil
    print "#{indent}#{value.inspect}"

  when Array
    print "#{indent}["
    value.each_with_index do |item, index|
      print_nested_value(item, depth + 1)
      print "," unless index == value.size - 1  # Print comma unless it's the last item
    end
    print "#{indent}]"

  when Hash
    print "#{indent}{"
    value.each_with_index do |(key, val), index|
      print "#{indent}  #{key}:"
      print_nested_value(val, depth +1)
#      if val.is_a?(Hash) || (val.is_a?(Array) && val.any? { |v| v.is_a?(Hash) })
#        puts "#{indent}  #{key}:"
#        print_nested_value(val, depth + 1)
#      else
#        puts "#{indent}  #{key}: #{val.inspect}"
#      end
      puts "," unless index == value.size - 1  # Print comma unless it's the last pair
    end
    print "#{indent}}"
  else
    puts "#{indent}{ value: #{value.age} }"
  end
end



