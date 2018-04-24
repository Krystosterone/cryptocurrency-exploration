module Script
  class RawMessage
    attr_reader :chunks

    def initialize(chunks)
      @chunks = chunks
    end

    def to_s
      @chunks.join(" ")
    end
  end
end
