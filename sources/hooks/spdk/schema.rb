module Schema

def self.validate
  Dry::Schema.JSON do

    required(:workload).filled(:string)

    required(:startup).hash do
      required(:spdk_dir).filled(:string)
      required(:media).filled(:string)
      required(:hyperthreading).filled(:integer).value(included_in?: [0, 1])
      required(:hugepages).filled(:integer, gt?: 0)
      required(:time).filled(:integer, gt?: 0)
    end

    required(:sweep).hash do
      required(:queue).array(:integer, min_size?: 1, gt?: 0)
      required(:size).array(:integer, min_size?: 1, gt?: 0)
      required(:operation).array(:string, min_size?: 1, included_in?: %w[read write randread randwrite rw randrw])
      required(:cores).array(:string, min_size?: 1)
      required(:iteration).array(:integer, min_size?: 1, gt?: 0)
    end

  end
end

end
