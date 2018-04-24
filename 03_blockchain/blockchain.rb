require "active_support/all"
require "base64"
require "digest"
require "openssl"

module Config
  class << self
    def digest(node)
      Digest::SHA256.hexdigest(node)
    end
  end
end

class Input

end

class Output
  def initialize(address:, key:, value:)
    @address = address
    @key = key
    @value = value
  end

  def payload
    payload = {
      address: @address,
      value: @value,
    }

    payload.merge(signature: Base64.encode64(@key.private_encrypt(Config.digest(payload.to_json))))
  end
end

class Transaction
  def initialize(inputs:, key:, outputs:)
    @inputs = inputs
    @key = key
    @outputs = outputs
  end

  def payload
    payload = {
      inputs: @inputs.map(&:payload),
      outputs: @outputs.map(&:payload),
    }

    payload.merge(signature: Base64.encode64(@key.private_encrypt(Config.digest(payload.to_json))))
  end
end

class GenesisTransaction < Transaction
  def initialize(**attributes)
    super inputs: [], **attributes
  end
end

class Block

end

class GenesisBlock < Block

end

class BlockChain

end

key = OpenSSL::PKey::RSA.new(2048)
genesis_transaction = GenesisTransaction.new(
  outputs: [
    Output.new(
      address: "krystosterone",
      key: key,
      value: 1_000_000,
    )
  ],
  key: key,
)
pp genesis_transaction.payload

transaction = Transaction.new(
  inputs: [],
  outputs: [
    Output.new(
      address: "xuorig",
      key: key,
      value: 10,
    )
  ],
  key: key,
)
pp transaction.payload
