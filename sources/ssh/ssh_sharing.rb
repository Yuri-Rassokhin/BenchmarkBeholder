
def ssh_sharing_enable
  # Path to SSH config file
  ssh_config = File.expand_path("~/.ssh/config")

  # Read the file and check if the line does NOT in it
  if !File.exist?(ssh_config) || !File.read(ssh_config).include?("Include ./ssh_shared")
    `./sources/ssh/ssh_sharing.sh`
  end
end

