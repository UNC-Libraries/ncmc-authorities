module NCMCAuthorities
  class Cluster
    attr_reader :key, :members

    def initialize(key)
      @key = key
      @members = []
      Cluster.hsh[key] ||= self
    end

    def members_except(name)
      members.reject { |member| member.equal? name }
    end

    def self.hsh
      @hsh ||= {}
    end
  end

  class ClusterHash < Hash

    def add(key)
      self[key] = Cluster.new(key)
    end
  end

end
