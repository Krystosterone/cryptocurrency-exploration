module Script
  class Builder
    OPERATION_TYPE = 0
    PUSHDATA_TYPE = 1

    def initialize
      @chunks = []
      @stack = []
    end

    def add_operation(value)
      @chunks << [OPERATION_TYPE, value]
      self
    end

    def add_pushdata
      @chunks << [PUSHDATA_TYPE]
      self
    end

    def stack(*values)
      @stack = values
      self
    end

    def chunks
      working_stack = @stack

      chunks = @chunks.reverse.each_with_object([]) do |chunk, memo|
        case chunk.first
        when OPERATION_TYPE; process_operation(chunk.second, working_stack, memo)
        when PUSHDATA_TYPE; process_pushdata(working_stack, memo)
        end
      end

      chunks.reverse
    end

    private

    def process_operation(chunk, working_stack, memo)
      case chunk
      when "OP_CHECKSIG"
        message = working_stack.pop
        key = working_stack.pop

        working_stack << key.private_encrypt(message)
        working_stack << Base64.strict_encode64(key.public_key.export)
        memo << chunk
      when "OP_EQUALVERIFY"
        working_stack << working_stack[-1]
        memo << chunk
      when "OP_HASH160"
        memo << Digest::RMD160.hexdigest(Digest::SHA256.digest(memo.pop))
        memo << chunk
      when "OP_DUP"
        working_stack.pop
        memo << chunk
      end
    end

    def process_pushdata(working_stack, memo)
      memo << working_stack.pop
    end
  end
end
