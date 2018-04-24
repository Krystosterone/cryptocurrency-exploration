module Script
  class CompressedMessage
    def initialize(hex_encoded_string)
      @hex_encoded_string = hex_encoded_string
    end

    def to_s
      @hex_encoded_string.unpack("H*").first
    end
  end
end
