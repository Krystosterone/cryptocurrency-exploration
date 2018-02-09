require "active_support/all"
require "concurrent"
require "httparty"
require "openssl"
require "sinatra"

Thread.abort_on_exception = true

peers = (ENV["PEERS"] || "").split(",")
key_pair = OpenSSL::PKey::RSA.new(2048)

$public_key = key_pair.public_key.export
$private_key = key_pair

$state = Concurrent::Hash.new
$peers = Concurrent::Array.new(peers)

post "/gossip" do
  params = JSON.parse(request.body.read)
  public_key = OpenSSL::PKey::RSA.new(Base64.decode64(params["public_key"]))
  decrypted_state = public_key.public_decrypt(Base64.decode64(params["signature"]))

  halt(:forbidden) if decrypted_state != digest(params["state"])

  params["state"].each do |identifier, payload|
    $state[identifier] =
      if payload["version"] > ($state.dig(identifier, "version") || 0)
        payload
      else
        $state[identifier]
      end
  end

  $state.to_json
end

# Following endpoints would never exist in a real system
# Useful just to trigger either updates or debug the node

post "/update" do
  params = JSON.parse(request.body.read)
  encoded_public_key = Base64.encode64($public_key)

  $state[encoded_public_key] =
    if $state.key?(encoded_public_key)
      {
        "data" => params["data"],
        "version" => $state[encoded_public_key]["version"] + 1,
      }
    else
      {
        "data" => params["data"],
        "version" => 1,
      }
    end

  gossip_payload.to_json
end

get "/inspect" do
  {
    "peers" => $peers,
    "public_key" => Base64.encode64($public_key),
    "state" => $state,
  }.to_json
end

private

def gossip
  $peers.each do |peer|
    begin
      HTTParty.post(
        "http://#{peer}/gossip",
        {
          body: gossip_payload.to_json,
          headers: { "Content-Type" => "application/json" },
        }
      )
    rescue Errno::ECONNREFUSED
      $peers.delete(peer)
    end
  end
end

def gossip_payload
  {
    "public_key" => Base64.encode64($public_key),
    "state" => $state,
    "signature" => Base64.encode64($private_key.private_encrypt(digest($state)))
  }
end

def digest(state)
  Digest::SHA256.hexdigest(state.to_json)
end

# Gossip every so often

Thread.new do
  loop do
    gossip
    sleep 3.seconds
  end
end
