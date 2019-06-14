require 'set'

module NCMCAuthorities
  class Cluster
    attr_reader :key, :members

    def initialize(key)
      @key = key
      @members = Set.new
    end

    def members_except(name)
      members.reject { |member| member.equal? name }
    end
  end

  class ClusterHash < Hash
    def add(key)
      self[key] = Cluster.new(key)
    end

    def key_lengths
      map { |k, v| [k, v.members.length] }.to_a.sort_by { |x| x[1] }.to_h
    end
  end
end
