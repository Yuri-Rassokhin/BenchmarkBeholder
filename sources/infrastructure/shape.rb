module Shape

def guess_shape
  shape = ""
  subshape = ""
  gpu_model = ""

  a10 = `lspci -n -n -k | grep -i 10de:2236 | wc -l`.to_i
  h100sxm80 = `lspci -n -n -k | grep -i 10de:2330 | wc -l`.to_i
  h100nvswitch = `lspci -n -n -k | grep -i 10de:22a3 | wc -l`.to_i
  a100nvswitch = `lspci -n -n -k | grep -i 10de:1af1 | wc -l`.to_i
  a100sxm40 = `lspci -n -n -k | grep -i 10de:20b0 | wc -l`.to_i
  a100sxm80 = `lspci -n -n -k | grep -i 10de:20b2 | wc -l`.to_i
  a100pci40 = `lspci -n -n -k | grep -i 10de:20b1 | wc -l`.to_i
  a100pci80 = `lspci -n -n -k | grep -i 10de:20b5 | wc -l`.to_i
  gh200 = `lspci -n -n -k | grep -i 10de:2342 | wc -l`.to_i

  if a10 > 0
    gpu_model = "NVIDIA A10"
    case a10
    when 4
      shape = "BM.GPU.A10"
    when 2
      shape = "VM.GPU.A10.2"
    when 1
      shape = "VM.GPU.A10.1"
    else
      shape = "unknown compute shape"
    end
  elsif h100sxm80 > 0
    gpu_model = "NVIDIA H100 SXM 80GB"
    case h100sxm80
    when 8
      shape = "BM.GPU.H100.8"
    when 4
      shape = "VM.GPU.H100.4"
    when 2
      shape = "VM.GPU.H100.2"
    when 1
      shape = "VM.GPU.H100.1"
    else
      shape = "unknown compute shape"
    end
  elsif a100sxm80 > 0
    gpu_model = "NVIDIA A100 SXM 80GB"
    shape = "BM.GPU.A100-v2.8" if a100sxm80 == 8
  elsif a100pci40 > 0
    gpu_model = "NVIDIA A100 PCIe 40GB"
    shape = "BM.GPU4.8" if a100pci40 == 8
  elsif gh200 > 0
    gpu_model = "NVIDIA GH200"
    shape = "TBD GH200" if gh200 == 1
  else
    shape = detect_cpu_based_shape
  end

  if shape.empty?
    "unknown compute shape"
  else
    [ shape, subshape ]
  end
end

def detect_cpu_based_shape
  shape = ""
  nvme_number = `lsblk | grep nvme | wc -l`.to_i
  cpu = `grep "model name" /proc/cpuinfo | sed -e 's/^.*: //' | head -n 1`.strip
  cores = `grep processor /proc/cpuinfo | wc -l`.to_i

  if cpu.include?("EPYC 7J13") && nvme_number == 8
    shape = "BM.DenseIO.E4"
  elsif cpu.include?("EPYC 7J13") && nvme_number < 8
    shape = "VM.DenseIO.E4"
  elsif cpu.include?("Xeon 6354") && nvme_number == 1
    shape = "BM.Optimized3.36"
  elsif cpu.include?("Platinum 8358") && cores == 128
    shape = "BM.Standard3.64"
  elsif cpu.include?("EPYC 7J13") && cores == 256
    shape = "BM.Standard.E4.128"
  elsif cpu.include?("EPYC 9J14") && cores == 192
    shape = "BM.Standard.E5.192"
  elsif cpu.include?("Altra Q80-30") && cores == 320
    shape = "BM.Standard.A1.160"
  elsif cpu.include?("Platinum 8358")
    shape = "VM.Standard3"
  elsif cpu.include?("EPYC 7551")
    shape = "VM.Standard.E2.1.Micro"
    subshape = "E2 generation"
  elsif cpu.include?("EPYC 7742")
    shape = "VM.Standard.E2.1.Micro"
    subshape = "E3 generation"
  elsif cpu.include?("EPYC 7J13")
    if cores > 2 || `free -h --giga --total | grep Total | awk '{print $2}' | sed 's/G//'`.to_i > 1
      shape = "VM.Standard.E4.Flex"
    else
      shape = "VM.Standard.E4.Flex or VM.Standard.E2.1.Micro (E4 generation)"
    end
  else
    shape = "unknown compute shape"
  end
  [ shape, subshape ]
end

end

