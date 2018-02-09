require "active_support/all"
require "httparty"

PROCESS_PATH = File.expand_path("../../00_gossip_protocol/node.rb", __FILE__)

$nodes = []

def run
  while command = gets
    case command
    when /^spawn cluster(.*)$/
      ($1 || "")
        .strip
        .split(/\s+/)
        .map { |value| value.split(":") }
        .map { |(node, peers)| [node, (peers || "").split(",")] }
        .each { |(node, peers)| spawn(node, peers.join(",")) }
    when /^spawn node(.*)$/
      arguments = extract_arguments($1)
      peers = arguments["peers"]
      port = arguments.fetch("port") { raise ArgumentError, "Missing mandatory option port" }

      spawn port, peers
    when /^list nodes$/
      print "Currently running nodes: #{$nodes}\n"
    when /^inspect nodes$/
      $nodes.each do |node|
        response = HTTParty.get("http://localhost:#{node}/inspect")
        parsed_response = JSON.parse(response)

        output = { "node" => node }.merge(parsed_response).to_yaml
        print output
      end
    else
      print "Unrecognized command\n"
    end
  end
end

private

def extract_arguments(blob)
  (blob || "")
    .strip
    .split("-")
    .select(&:present?)
    .map(&:strip)
    .map { |command| command.split(/\s+/) }
    .to_h
end

def suppress_output
  begin
    original_stderr = $stderr.clone
    original_stdout = $stdout.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    $stdout.reopen(File.new('/dev/null', 'w'))
    retval = yield
  rescue Exception => e
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
    raise e
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  retval
end

def spawn(port, peers)
  fork do
    suppress_output do
      exec "PEERS=#{peers} ruby #{PROCESS_PATH} -p #{port}"
    end
  end
  print "Spawning node on port #{port} with peers #{peers}\n"

  $nodes << port
end

run
