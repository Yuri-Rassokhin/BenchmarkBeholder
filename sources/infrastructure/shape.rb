module Shape

def guess_shape(platform)
  case platform
  when "oci"
    shape = `curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | grep -iw shape | awk '{print $2}' | sed 's/"//g' | sed 's/,//'`
  when "azure"
    shape = `curl -s --connect-timeout 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | grep "vmSize" | awk '{ print $2 }'`
  when "aws"
    shape = `curl -s http://169.254.169.254/latest/meta-data/instance-type`
  else
    shape = "unknown"
  end
  shape.strip.gsub(/["",]/, '') # Ensure leading/trailing whitespace is removed
end

end

