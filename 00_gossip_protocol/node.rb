require "active_support/all"
require "byebug"
require "concurrent"
require "httparty"
require "openssl"
require "sinatra"

Thread.abort_on_exception = true

peers = (ENV["PEERS"] || "").split(",").map(&:to_i).compact

$key = OpenSSL::PKey::RSA.new(2048)
$public_key = $key.public_key.export

$state = Concurrent::Hash.new
$peers = Concurrent::Array.new(peers)

before do
  @json_params = JSON.parse(request.body.read) rescue {}
end

post "/gossip" do
  # Ensuring all required params are there
  return halt(400) if missing_params?(%w(peers public_key state signature))

  # Forbid any payload that has been forged with
  return halt(403) unless valid_payload?

  # Update state and peers
  update

  # Answer back with own gossip payload so that requester can update it's own peers and state
  gossip_payload.to_json
end

# Following endpoints would never exist in a real system
# Useful just to trigger either updates or debug the node
post "/update" do
  encoded_public_key = Base64.encode64($public_key)

  payload = {
    "data" => @json_params["data"],
    "version" => $state.key?(encoded_public_key) ? $state[encoded_public_key]["version"] + 1 : 1,
  }

  $state[encoded_public_key] =
    payload.merge("signature" => Base64.encode64($key.private_encrypt(digest(payload))))

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

def missing_params?(required_params)
  !required_params.all? { |required_param| required_param.in?(@json_params.keys) }
end

def valid_payload?
  public_key = OpenSSL::PKey::RSA.new(Base64.decode64(@json_params["public_key"]))
  decrypted_state = public_key.public_decrypt(Base64.decode64(@json_params["signature"]))

  return false if decrypted_state != digest(@json_params.except("signature"))

  @json_params["state"].all? do |raw_public_key, payload|
    node_public_key = OpenSSL::PKey::RSA.new(Base64.decode64(raw_public_key))
    decrypted_payload = node_public_key.public_decrypt(Base64.decode64(payload["signature"]))

    decrypted_payload == digest(payload.except("signature"))
  end
rescue OpenSSL::PKey::RSAError
  false
end

def gossip
  $peers.each do |peer|
    begin
      response =
        HTTParty.post(
          "http://localhost:#{peer}/gossip",
          {
            body: gossip_payload.to_json,
            headers: { "Content-Type" => "application/json" },
          }
        )
      update(JSON.parse(response))
    rescue Errno::ECONNREFUSED
      $peers.delete(peer)
    end
  end
end

def gossip_payload
  payload = {
    # Add self to peers
    "peers" => $peers + [settings.port],
    "public_key" => Base64.encode64($public_key),
    "state" => $state,
  }

  payload.merge("signature" => Base64.encode64($key.private_encrypt(digest(payload))))
end

def update
  # Update state of node for data that is older than what we currently have
  @json_params["state"].each do |public_key, payload|
    $state[public_key] =
      if payload["version"] > ($state.dig(public_key, "version") || 0)
        payload
      else
        $state[public_key]
      end
  end

  # Update peers, dedup and remove self
  $peers = ($peers + @json_params["peers"]).uniq - [settings.port]
end

def digest(state)
  Digest::SHA256.hexdigest(state.to_json)
end

# Gossip every so often
Thread.new do
  loop do
    sleep 3.seconds
    gossip
  end
end
