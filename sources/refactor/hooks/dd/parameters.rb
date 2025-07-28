
SCHEMA = Dry::Schema.JSON do

  required(:workload).hash do
    required(:name).filled(:string)
    required(:protocol).filled(:string)
    required(:actor).filled(:string)
    required(:target).filled(:string)
    required(:iterations).filled(:integer, gt?: 0)
    required(:total_size).filled(:integer, gt?: 0)
  end

  required(:parameters).hash do
    required(:scheduler).array(:string, min_size?: 1, included_in?: %w[none bfq mq-deadline kyber])
    required(:size).array(:integer, min_size?: 1, gt?: 0)
    required(:operation).array(:string, min_size?: 1, included_in?: %w[read write])
  end

end
