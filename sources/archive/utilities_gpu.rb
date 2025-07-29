module UtilitiesGPU

def gpu?
  if `lspci | grep -i nvidia`.empty?
    return false
  elsif `which nvidia-smi`.empty?
    return false
  end
  true
end

def get_nvidia_versions

def gpu?
  if `lspci | grep -i nvidia`.empty?
    return false
  elsif `which nvidia-smi`.empty?
    return false
  end
  true
end

  if gpu?
    nvidia_driver_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $6}'`.strip
    nvidia_cuda_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $9}'`.strip
  else
    nvidia_driver_version = "N/A"
    nvidia_cuda_version = "N/A"
  end
  [nvidia_driver_version, nvidia_cuda_version]
end

def get_gpu_consumption(number_installed_gpus)

def gpu?
  if `lspci | grep -i nvidia`.empty?
    return false
  elsif `which nvidia-smi`.empty?
    return false
  end
  true
end

  if gpu?
    consumption = `nvidia-smi --query-gpu=utilization.gpu --format=csv`
    gpu_consumptions = Array.new(number_installed_gpus) { |i| consumption.split("\n")[i + 1].split(',')[0].strip.to_i rescue -1 }
    consumption = `nvidia-smi --query-gpu=memory.used --format=csv`
    gpu_ram_consumptions = Array.new(number_installed_gpus) { |i| consumption.split("\n")[i + 1].split(',')[0].strip.to_i rescue -1 }
    gpu_ram_per_device = `nvidia-smi --query-gpu=memory.total --format=csv | tac | head -1 | awk '{print $1}'`.strip
  else
    gpu_consumptions = "N/A"
    gpu_ram_consumptions = "N/A"
    gpu_ram_per_device = "N/A"
  end
  { gpu_consumptions: gpu_consumptions, gpu_ram_consumptions: gpu_ram_consumptions, gpu_ram_per_device: gpu_ram_per_device }
end

def check_gpu_idle(gpu_consumptions)
def gpu?
  if `lspci | grep -i nvidia`.empty?
    return false
  elsif `which nvidia-smi`.empty?
    return false
  end
  true
end

  return if !gpu?
  load = gpu_consumptions.sum
  error("GPU load >= 10%, no good for benchmarking") if load >= 10
end

def check_gds(filesystem)
def gpu?
  if `lspci | grep -i nvidia`.empty?
    return false
  elsif `which nvidia-smi`.empty?
    return false
  end
  true
end

  if !gpu?
    gds_supported = "no gpu"
  else
    gds_supported = if !%w[ext4 xfs beegfs].include?(filesystem)
                    "no"
                  elsif `lsmod | grep nvidia_fs | wc -l`.strip == "0"
                    "no"
                  elsif File.exist?('/usr/local/cuda/gds/tools/gdscheck') && `#{File.dirname(File.expand_path(__FILE__))}/gdscheck -p | grep Supported | grep -v "Driver Info" | wc -l`.strip == "0"
                    "no"
                  else
                    "yes"
                  end
  end
  puts gds_supported
end

end
