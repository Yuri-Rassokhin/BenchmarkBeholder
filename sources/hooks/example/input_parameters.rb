module InputParameters

# ADD DEFINITIONS OF WORKLOAD-SPECIFIC STARTUP PARAMETERS
def startup_parameters
  {
  }
end

# ADD YOUR DEFINITIONS OF WORKLOAD-SPECIFIC ITERATABLE PARAMETERS
def iterate_parameters
  {
    iterate_schedulers: VStr.new(non_empty: true, comma_separated: true, iteratable: true)
  }
end

end
