require_relative "script"

# hex_encoded_message = Script::HexEncodedMessage.new(["OP_DUP", "OP_HASH160", "fa0692278afe508514b5ffee8fe5e97732ce0669", "OP_EQUALVERIFY", "OP_CHECKSIG"])
# p hex_encoded_message.to_s
#
# compressed_message = Script::CompressedMessage.new(hex_encoded_message.to_s)
# p compressed_message.to_s
#
# p compressed_message.to_s == "76a914fa0692278afe508514b5ffee8fe5e97732ce066988ac"
#
# hex_encoded_message = Script::HexEncodedMessage.new(["30450221009f44f5679776dfa5227db7f99f7307f90561901077dc8489518278b1458eeddf022028d2bb1187791b7d3302463802e0e6f786c849f2bac25abe46d7c3f2b1b3dd4c01", "04fcf07bb1222f7925f2b7cc15183a40443c578e62ea17100aa3b44ba66905c95d4980aec4cd2f6eb426d1b1ec45d76724f26901099416b9265b76ba67c8b0b73d"])
# p hex_encoded_message.to_s
#
# compressed_message = Script::CompressedMessage.new(hex_encoded_message.to_s)
# p compressed_message.to_s
#
# p compressed_message.to_s == "4830450221009f44f5679776dfa5227db7f99f7307f90561901077dc8489518278b1458eeddf022028d2bb1187791b7d3302463802e0e6f786c849f2bac25abe46d7c3f2b1b3dd4c014104fcf07bb1222f7925f2b7cc15183a40443c578e62ea17100aa3b44ba66905c95d4980aec4cd2f6eb426d1b1ec45d76724f26901099416b9265b76ba67c8b0b73d"

# -----------------

# key = OpenSSL::PKey::RSA.new(2048)
# message = "Hello world!"
# hashed_message = Digest::SHA256.hexdigest(message)
#
# chunks =
#   Script::Builder
#     .new
#     .add_operation("OP_DUP")
#     .add_operation("OP_HASH160")
#     .add_pushdata
#     .add_operation("OP_EQUALVERIFY")
#     .add_operation("OP_CHECKSIG")
#     .stack(key, hashed_message)
#     .chunks
#
# p chunks
#
# raw_message = Script::RawMessage.new(chunks)
# p raw_message.to_s
#
# hex_encoded_message = Script::HexEncodedMessage.new(chunks)
# p hex_encoded_message.to_s
#
# compressed_message = Script::CompressedMessage.new(hex_encoded_message.to_s)
# p compressed_message.to_s
#
# encrypted_message = Base64.strict_encode64(key.private_encrypt(hashed_message))
# public_key = Base64.strict_encode64(key.public_key.export)
#
# script = Script::Run.new(raw_message.to_s)
# p script.call("#{encrypted_message} #{public_key}")

# -----------------

# key = OpenSSL::PKey::RSA.new(2048)
# public_key = Base64.strict_encode64(key.public_key.export)
#
# message = "Hello world!"
# hashed_message = Digest::SHA256.hexdigest(message)
# encrypted_message = Base64.strict_encode64(key.private_encrypt(hashed_message))
#
# script_key = Digest::RMD160.hexdigest(Digest::SHA256.digest(public_key))
#
# script = Script::Run.new("OP_DUP OP_HASH160 #{script_key} OP_EQUALVERIFY OP_CHECKSIG")
# p script.call("#{encrypted_message} #{public_key}")
