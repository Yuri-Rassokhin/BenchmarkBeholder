module Shape

def guess_shape

  # Check if it's OCI
  shape = `curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | grep -iw shape | awk '{print $2}' | sed 's/"//g' | sed 's/,//'`
  return shape.strip.gsub(/["",]/, '') if shape != ""

  # Check if it's Azure
  shape = `curl -s --connect-timeout 3 -H "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | grep "vmSize" | awk '{ print $2 }'`
  return shape.strip.gsub(/["",]/, '') if shape != ""

  # Check if it's AWS
  shape = `curl -s http://169.254.169.254/latest/meta-data/instance-type`
  return shape.strip.gsub(/["",]/, '') if shape != "No such metadata item"
  
  "unknown"
end

end

