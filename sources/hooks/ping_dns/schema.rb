module Schema

def self.validate
  Dry::Schema.JSON do
    required(:workload).filled(:string)
    required(:sweep).hash do
      required(:dns).array(:string, min_size?: 1, included_in?: %w[8.8.8.8 1.1.1.1 208.67.222.222])
      required(:size).array(:integer, min_size?: 1, gteq?: 16)
    end
  end
end

end
