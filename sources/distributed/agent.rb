require 'net/ssh'
require 'json'
require 'rubygems'
require 'sourcify'
require 'ruby2ruby'
require 'base64'

require './sources/infrastructure/utilities_general.rb'
require './sources/infrastructure/utilities_gpu.rb'
require './sources/infrastructure/shape.rb'

class Agent < Object

  include UtilitiesGeneral
  include UtilitiesGPU
  include Shape

  attr_accessor :user, :password, :url
  attr_reader :error

  def initialize(user, url = nil)
    @user = user
    @password = nil
    # if .run returns nil, @error may store explanation of the error
    @error = nil
    @url = url
    @utilities = utilities_set
  end

  # @param method [symbol] symbolic name of a method to execute on remote host, included in utilities
  # @param *arg [Array] arbitrary arguments to pass to the method
  # @return [String] textual output of the method
  def run(host, method, *args)
    raise "Remote URL not set" unless host
    raise "SSH user not set" unless user
    @error = nil
    case args.size
    when 0 then res_args = nil
    when 1 then
      res_args = transfer(args[0])
    else
      res_args = ""
      args.each_with_index do |arg,index|
        res_args << "#{transfer(arg)}"
        res_args = "#{res_args}, " unless index == args.size-1
      end
    end
    res_args = res_args ? "(#{res_args})" : "()"
    code = "#{@utilities}" + self.method(method).source << "puts #{method}#{res_args}\n"
    execute_remote(host, code)
  end
 
  def detach(host, method, *args)
    raise "Remote URL not set" unless host
    raise "SSH user not set" unless user
    @error = nil
    case args.size
    when 0 then res_args = nil
    when 1 then
      res_args = transfer(args[0])
    else
      res_args = ""
      args.each_with_index do |arg,index|
        res_args << "#{transfer(arg)}"
        res_args = "#{res_args}, " unless index == args.size-1
      end
    end
    res_args = res_args ? "(#{res_args})" : "()"
    code = "#{@utilities}" + self.method(method).source << "puts #{method}#{res_args}\n"
    detach_remote(host, code)
  end

  # syntactic sugar for when you run lots of consequitive methods on the same host
  def run!(method, *args)
    raise "url is undefined in the agent" unless @url
    run(@url, method, *args)
  end

  def detach!(method, *args)
    raise "url is undefined in the agent" unless @url
    detach(@url, methos, *args)
  end

  def available?(host)
    test = `ssh -o StrictHostKeyChecking=no #{@user}@#{host} sudo ls / 2>&1`
    if test.include?("terminal")
      set_error("passwordless sudo required on '#{host}'")
      return false
    elsif !test.include?("root")
      set_error("host #{host}:22 is unreachable via SSH")
      return false
    end
    return true
  end

private

def utilities_set
  utilities = File.read("./sources/infrastructure/utilities_general.rb")
  utilities = File.read("./sources/infrastructure/utilities_gpu.rb") + utilities
  utilities = File.read("./sources/infrastructure/shape.rb") + utilities
  return utilities + "include UtilitiesGeneral\n" + "include UtilitiesGPU\n" + "include Shape\n"
end

  def to_bool(value)
    return value == "true"
  end

  def float?(value)
    Float(value) ? true : false
    rescue
      false
  end

  def integer?(value)
    Integer(value) ? true : false
    rescue
      false
  end

  def set_error(raw_output)
    @error = raw_output
  end

  def output(raw_output)
    out = raw_output.downcase.strip

    if [ "true", "false" ].include?(out)
      return to_bool(out)
    elsif integer?(out)
      return out.to_i
    elsif float?(out)
      return out.to_f
    else
      begin
        res = eval(out)
        return res
      rescue SyntaxError, NameError => e
        return out.to_s
      end
#      return out.to_s
    end
  end



  # NOTE: only one instance of this method can run at a time, otherwise they'll compete for temp file and output variable
def detach_remote(host, code)
  code64 = Base64.encode64(code)
  pid = fork do
    begin
      Net::SSH.start(host, @user, password: @password) do |ssh|
        puts "STARTING"
        ssh.exec!("echo '#{code64}' > /tmp/remote_method_call.64")
        ssh.exec!("base64 --decode /tmp/remote_method_call.64 > /tmp/remote_method_call.rb")
        ssh.exec!("nohup ruby /tmp/remote_method_call.rb > /dev/null 2>&1")
        output("")
        puts "DONE"
      end
    rescue => e
      # TODO: message error to TG
      # You could add a mechanism to log or send a message here
    ensure
      puts "COMPLETED"
      # TODO: report completion in detached mode
    end
  end
  Process.detach(pid)
end

  def execute_remote(host, code)
    # convert the code from raw text to Base64 to avoid any modification of $1, $2, etc, if any in the code
    code64 = Base64.encode64(code)
    Net::SSH.start(host, @user, password: @password) do |ssh|
      ssh.exec!("echo '#{code64}' > /tmp/remote_method_call.64")
      ssh.exec!("base64 --decode /tmp/remote_method_call.64 > /tmp/remote_method_call.rb")
      ttt = ssh.exec!("ruby /tmp/remote_method_call.rb 2>&1")
      sss = output(ttt)
      sss
#      ssh.exec!("rm /tmp/remote_method_call.{rb,64}")
    end
  rescue => e
    @error = "remote execution failed at '#{host}': #{e.message}"
    nil
  end

def transfer(value, depth = 0)
  indent = '  ' * depth  # Two spaces per depth level

  case value

  when String, Numeric, Symbol, true, false, nil
    return "#{indent}#{value.inspect}"

  when Array
    res = "#{indent}["
    value.each_with_index do |item, index|
      res << transfer(item, depth + 1)
      res << "," unless index == value.size - 1  # Print comma unless it's the last item
    end
    res << "#{indent}]"
    return res

  when Hash
    res = "#{indent}{"
    value.each_with_index do |(key, val), index|
      res << "#{indent}  #{key}:"
      res << transfer(val, depth +1)
      res << "," unless index == value.size - 1  # Print comma unless it's the last pair
    end
    res << "#{indent}}"
    return res
  else

    # here, newline should be
    raise "distributed platform: class #{value.class} must respond on 'value'" unless value.respond_to?(:value)
    return "#{indent}#{transfer(value.value)}"
  end
end


end

