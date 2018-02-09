require "active_support/all"
require "httparty"

explored_nodes = []
remaining_nodes = [ENV["ENTRY"].to_i]

while remaining_nodes.present?
  node = remaining_nodes.shift
  response = HTTParty.get("http://localhost:#{node}/inspect")
  parsed_response = JSON.parse(response)

  explored_nodes = (explored_nodes + [node]).uniq
  remaining_nodes = (remaining_nodes + parsed_response["peers"] - explored_nodes).uniq

  output = { "node" => node }.merge(parsed_response).to_yaml
  print output
end
