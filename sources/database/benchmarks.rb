
class Benchmarks

#def codes
#    return `mysql -N -B -e "select code from BENCHMARKING.projects;"`.split("\n")
#end

#def projects
#  warning("this yet to be implemented")
#end

def initialize(benchmark)
  @benchmark_table = benchmark
end

def load()
end

end

