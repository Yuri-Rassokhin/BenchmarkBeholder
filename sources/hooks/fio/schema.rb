module Schema

def self.validate
  Dry::Schema.JSON do

    required(:workload).filled(:string)

    required(:misc).hash do
      required(:target).filled(:string)
      required(:total_size).filled(:integer, gt?: 0)
    end

    required(:sweep).hash do
      required(:scheduler).array(:string, min_size?: 1, included_in?: %w[none bfq mq-deadline kyber])
      required(:size).array(:integer, min_size?: 1, gt?: 0)
      required(:operation).array(:string, min_size?: 1, included_in?: %w[read write randread randwrite])
      required(:ioengine).array(:string, min_size?: 1, included_in?: %w[libaio])
      required(:iodepth).array(:integer, min_size?: 1, gt?: 0)
      required(:processes).array(:integer, min_size?: 1, gt?: 0)
      required(:iteration).array(:integer, min_size?: 1, gt?: 0)
    end

  end
end

end
