module Script
  class Run
    def initialize(script)
      @script = script
    end

    def call(stack)
      working_stack = stack.split(" ")

      chunks.reduce(true) do |_, chunk|
        case chunk
        when "OP_DUP"
          working_stack << working_stack[-1]
        when "OP_HASH160"
          working_stack[-1] = Digest::RMD160.hexdigest(Digest::SHA256.digest(working_stack[-1]))
        when "OP_EQUALVERIFY"
          break false if working_stack.pop != working_stack.pop
        when "OP_CHECKSIG"
          begin
            key = OpenSSL::PKey::RSA.new(Base64.strict_decode64(working_stack.pop))
            working_stack << key.public_decrypt(Base64.strict_decode64(working_stack.pop))
          rescue
            break false
          end
        else
          working_stack << chunk
        end

        true
      end
    end

    private

    def chunks
      @script.split(" ")
    end
  end
end
