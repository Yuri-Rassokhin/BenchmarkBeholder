require 'tempfile'

class Hook

private

def prepare
  size = @config[:workload][:total_size]
  file = @config.target

  @config.hosts.each do |h|
    @logger.info "creating target file #{file} of the size #{size}, rounded to megabytes, on #{h}"
    Global.run(binding, h, proc do
      File.open(file, "wb") do |f|
        block = "\0" * 1024 * 1024  # 1MB
        (size / block.size).times { f.write(block) }
      end
    end
  end
end

  @logger.info "creating log ./bbh-#{@config.hook}-#{@config[:parameters][:series]}-result.csv"
end

def setup
  result = {}

  # NOTE: so far, indirect access is hardcoded for A). simplicity (to avoid validity checks with with ioengines, and B. practical need
  func(:add, :command) do |v|
    "#{@config.actor} --direct=0 --unit_base=8 --kb_base=1024 --rw=#{v.operation} --bs=#{v.size} --ioengine=#{v.ioengine} --iodepth=#{v.iodepth} --runtime=15 --numjobs=#{v.processes} --time_based --group_reporting --name=bbh_fio --eta-newline=1 --filename=#{@config.target}".strip
  end

  func(:add, :result, hide: true) do |v|
    unless result[@counter]
      Scheduler.switch(@logger, v.scheduler)
      result[@counter] = Global.run(binding, v.host, proc { `#{v.command}`.strip })
    end
    result[@counter]
  end

  func(:add, :iops) do |v|
    line = v.result.lines.select { |l| l.include?("iops") && l.include?("avg=") }.last
    res = line&.match(/avg=([\d.]+)/)&.captures&.first&.to_i || 0.0
    @logger.info "  iops: #{res}"
    res
  end

  func(:add, :bandwidth) do |v|
    bw = v.result[/ \((\d+)kB\/s-/, 1].to_f
    res = Utilities.convert_units(@logger, bw, from: "KB/s", to: v.units, precision: @config[:workload][:precision])
    @logger.info "  bandwidth: #{res} #{v.units}"
    res
  end

  func(:add, :units) { @config[:workload][:units] }

  # standard functions for infrastructure metrics
  Platform.add_infra(space: self, gpu: false)
end

end

