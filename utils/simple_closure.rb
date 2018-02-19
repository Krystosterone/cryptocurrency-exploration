class SimpleClosure
  class << self
    def call(*arguments)
      new(*arguments).call
    end
  end
end
