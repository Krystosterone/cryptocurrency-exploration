require "spec_helper"

RSpec.describe "MerkleTree" do
  subject(:merkle_tree) { MerkleTree.new(("a".."e").to_a) }

  describe "#root_hash" do
    let(:actual_merkle_root) do
      digest_nodes(
        digest_nodes(
          digest_nodes(
            Config.digest("a"),
            Config.digest("b"),
          ),
          digest_nodes(
            Config.digest("c"),
            Config.digest("d"),
          ),
        ),
        digest_nodes(
          digest_nodes(
            Config.digest("e"),
            Config.digest("e"),
          ),
          digest_nodes(
            Config.digest("e"),
            Config.digest("e"),
          ),
        )
      )
    end

    it "returns the merkle root" do
      expect(merkle_tree.root_hash).to eq(actual_merkle_root)
    end
  end

  describe "#audit_proof" do
    ("a".."e").each do |leaf|
      leaf_hash = Config.digest(leaf)

      context "with leaf #{leaf}" do
        it "returns the correct intermediate hashes" do
          intermediate_hashes = merkle_tree.audit_proof(leaf_hash)
          expect(computed_merkle_root(leaf_hash, intermediate_hashes)).to eq(merkle_tree.root_hash)
        end
      end
    end
  end

  private

  def digest_nodes(*nodes)
    Config.digest(nodes.sort.join)
  end

  def computed_merkle_root(target_hash, intermediate_hashes)
    intermediate_hashes.reduce(target_hash, &method(:digest_nodes))
  end
end
