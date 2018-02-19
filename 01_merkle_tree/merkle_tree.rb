require "active_support/all"
require "byebug"
require "digest"
require_relative "../utils/simple_closure"

module Config
  class << self
    def digest(node)
      Digest::SHA256.hexdigest(node)
    end
  end
end

class MerkleTree
  def initialize(leaves)
    @leaves = leaves
  end

  def audit_proof(leaf_hash)
    target_hash = leaf_hash
    intermediate_hashes = []

    enumerator.each do |relationships|
      # Find parent and siblings of the hash we're now looking for
      parent, *target_siblings = relationships.find { |_, *siblings| siblings.include?(target_hash) }

      # Store it's sibling into the intermediate hashes
      sibling_difference = target_siblings - [target_hash]
      intermediate_hash = sibling_difference.empty? ? target_siblings.first : sibling_difference.first
      intermediate_hashes << intermediate_hash

      # And go up a level, now searching for it's sibling
      target_hash = parent
    end

    # Returns all necessary hashes to validate if leaf hash was part of this tree
    intermediate_hashes
  end

  def root_hash
    enumerator.to_a.last.first.first
  end

  private

  def enumerator
    Enumerator.new(&method(:iterate))
  end

  def iterate(yielder)
    nodes = @leaves.map(&Config.method(:digest))

    while nodes.size > 1
      # Correct for unbalanced subtree by duplicating the last entry
      nodes << nodes[-1] if nodes.size % 2 != 0

      # Map node relationships with [0] => parent and [1], [2] being the children
      relationships = nodes.each_slice(2).each_with_object([]) do |children, memo|
        memo << [Config.digest(children.sort.join)] + children
      end

      # Only keep parents as nodes to iterate on
      nodes = relationships.map(&:first)

      # But yield [parent, *children]
      yielder << relationships
    end
  end
end

class Renderer < SimpleClosure
  HASH_TRIM_SIZE = 6
  MINIMUM_SPACING = 3

  def initialize(merkle_tree)
    @merkle_tree = merkle_tree
  end

  def call
    tree_list.reverse.each_with_object("") do |siblings, memo|
      level_nodes = siblings.flatten.map { |node| node.first(HASH_TRIM_SIZE) }.join(" ")
      memo << "#{level_nodes}\n"
    end
  end

  private

  def tree_list
    output = relationship_list.reduce([]) do |memo, relationships|
      memo << relationships.flat_map { |_, *siblings| siblings }
    end
    output << [merkle_root]
  end

  def merkle_root
    @merkle_tree.root_hash
  end

  def relationship_list
    @merkle_tree.enumerator.to_a
  end
end
