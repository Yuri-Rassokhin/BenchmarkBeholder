module UtilitiesGPU

def get_nvidia_versions
  error("nvidia-smi is missing") if `which nvidia-smi`.empty?

  nvidia_driver_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $6}'`.strip
  nvidia_cuda_version = `nvidia-smi | grep NVIDIA-SMI | awk '{print $9}'`.strip
  [nvidia_driver_version, nvidia_cuda_version]
end

def get_gpu_consumption(number_installed_gpus)
  consumption = `nvidia-smi --query-gpu=utilization.gpu --format=csv`
  gpu_consumptions = Array.new(number_installed_gpus) { |i| consumption.split("\n")[i + 1].split(',')[0].strip.to_i rescue -1 }

  consumption = `nvidia-smi --query-gpu=memory.used --format=csv`
  gpu_ram_consumptions = Array.new(number_installed_gpus) { |i| consumption.split("\n")[i + 1].split(',')[0].strip.to_i rescue -1 }

  gpu_ram_per_device = `nvidia-smi --query-gpu=memory.total --format=csv | tac | head -1 | awk '{print $1}'`.strip

  { gpu_consumptions: gpu_consumptions, gpu_ram_consumptions: gpu_ram_consumptions, gpu_ram_per_device: gpu_ram_per_device }
end

def check_gpu_idle(gpu_consumptions)
  load = gpu_consumptions.sum
  error("GPU load >= 10%, no good for benchmarking") if load >= 10
end

def check_gds(filesystem)
  gds_supported = if !%w[ext4 xfs beegfs].include?(filesystem)
                    "No"
                  elsif `lsmod | grep nvidia_fs | wc -l`.strip == "0"
                    "No"
                  elsif File.exist?('/usr/local/cuda/gds/tools/gdscheck') && `#{File.dirname(File.expand_path(__FILE__))}/gdscheck -p | grep Supported | grep -v "Driver Info" | wc -l`.strip == "0"
                    "No"
                  else
                    "Yes"
                  end
  puts gds_supported
end

end
