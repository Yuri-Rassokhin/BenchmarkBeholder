
SCHEMA = Dry::Schema.JSON do

  required(:workload).hash do
    required(:protocol).filled(:string, included_in?: %w[file http http])
    required(:actor).filled(:string)
    required(:target).filled(:string)
    required(:iterations).filled(:integer, gt?: 0)
  end

  required(:parameters).hash do
    required(:schedulers).array(:string, min_size?: 1, included_in?: %w[none bfq deadline-mq kyber])
    required(:size).array(:integer, min_size?: 1)
    required(:operations).array(:string, min_size?: 1, included_in?: %w[read write randread randwrite])
  end

end
