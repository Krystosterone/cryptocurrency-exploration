module Script
  class HexEncodedMessage
    OP_PUSHDATA1 = 76
    OP_PUSHDATA2 = 77
    OP_PUSHDATA4 = 78

    def initialize(chunks)
      @chunks = chunks
    end

    def to_s
      @chunks.reduce("") do |memo, chunk|
        memo <<
          if OPERATIONS.key?(chunk)
            [OPERATIONS.fetch(chunk)].pack("C*")
          else
            pack([chunk].pack("H*"))
          end
      end
    end

    private

    def pack(data)
      size = data.bytesize

      head =
        if size < OP_PUSHDATA1
           [size].pack("C")
         elsif size <= 0xff
           [OP_PUSHDATA1, size].pack("CC")
         elsif size <= 0xffff
           [OP_PUSHDATA2, size].pack("Cv")
         else
           [OP_PUSHDATA4, size].pack("CV")
        end

      head + data
    end
  end
end
