require "active_support/all"
require "base64"
require "byebug"
require "digest"
require "openssl"
require_relative "../utils/simple_closure"
require_relative "script/builder"
require_relative "script/compressed_message"
require_relative "script/hex_encoded_message"
require_relative "script/raw_message"
require_relative "script/run"

# There a few different data formats a script can take
# For this exercise, we'll categorize them as such
#
# A Script::RawMessage has the following format:
#   OP_DUP OP_HASH160 17977bca1b6287a5e6559c57ef4b6525e9d7ded6 OP_EQUALVERIFY OP_CHECKSIG
#
# A Script::HexEncodedMessage has the following format:
#   v\xA9\x14\xFA\x06\x92'\x8A\xFEP\x85\x14\xB5\xFF\xEE\x8F\xE5\xE9w2\xCE\x06i\x88\xAC
#
# A Script::CompressedMessage has the following format:
#   76a914fa0692278afe508514b5ffee8fe5e97732ce066988ac

module Script
  OPERATIONS = {
    "OP_DUP" => 118,
    "OP_HASH160" => 169,
    "OP_EQUALVERIFY" => 136,
    "OP_CHECKSIG" => 172,
  }
end
