module Schema
  module_function

def validate
  Dry::Schema.JSON do

    required(:workload).hash do
      required(:hook).filled(:string)
      required(:actor).filled(:string)
      required(:protocol).filled(:string, included_in?: %w[file block])
      required(:target).filled(:string)
      required(:iterations).filled(:integer, gt?: 0)
      required(:total_size).filled(:integer, gt?: 0)
      required(:units).filled(:string)
      required(:precision).filled(:integer, gt?: 0)
    end

    required(:parameters).hash do
      required(:scheduler).array(:string, min_size?: 1, included_in?: %w[none bfq mq-deadline kyber])
      required(:block_size).array(:integer, min_size?: 1, gt?: 0)
      required(:operation).array(:string, min_size?: 1, included_in?: %w[read write randread randwrite])
      required(:ioengine).array(:string, min_size?: 1, included_in?: %w[libaio])
      required(:iodepth).array(:integer, min_size?: 1, gt?: 0)
      required(:processes).array(:integer, min_size?: 1, gt?: 0)
    end

  end
end

end
