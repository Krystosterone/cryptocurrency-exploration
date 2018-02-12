require "spec_helper"

RSpec.describe "node" do
  let(:key) { OpenSSL::PKey::RSA.new(2048) }
  let(:public_key) { key.public_key.export }
  let(:wrong_key) { OpenSSL::PKey::RSA.new(2048) }

  describe "POST /gossip" do
    context "when missing params" do
      it "returns a bad request status code" do
        post "/gossip", {}.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(400)
      end
    end

    context "when the root payload is not properly signed" do
      let(:payload) do
        {
          "peers" => [],
          "public_key" => Base64.encode64(public_key),
          "state" => {},
        }
      end
      let(:signed_payload) do
        payload.merge(
          "signature" => Base64.encode64(wrong_key.private_encrypt(Digest::SHA256.hexdigest(payload.to_json)))
        )
      end

      it "returns a forbidden status code" do
        post "/gossip", signed_payload.to_json, { "CONTENT_TYPE" => "application/json" }

        expect(last_response.status).to eq(403)
      end
    end

    context "when the root payload is properly signed" do
      context "when one of the states has not been properly signed" do
        let(:payload) do
          {
            "peers" => [],
            "public_key" => Base64.encode64(public_key),
            "state" => { Base64.encode64(public_key) => signed_state_entry_payload },
          }
        end
        let(:signed_payload) { payload.merge("signature" => sign(payload, key)) }
        let(:signed_state_entry_payload) do
          state_entry_payload.merge("signature" => sign(state_entry_payload, wrong_key))
        end
        let(:state_entry_payload) do
          { "data" => "some tampered data", "version" => 1 }
        end

        it "returns a forbidden status code" do
          post "/gossip", signed_payload.to_json, { "CONTENT_TYPE" => "application/json" }

          expect(last_response.status).to eq(403)
        end
      end

      context "when states have been untampered with" do
        let(:payload) do
          {
            "peers" => [],
            "public_key" => Base64.encode64(public_key),
            "state" => { Base64.encode64(public_key) => signed_state_entry_payload },
          }
        end
        let(:signed_payload) { payload.merge("signature" => sign(payload, key)) }
        let(:signed_state_entry_payload) do
          state_entry_payload.merge("signature" => sign(state_entry_payload, key))
        end
        let(:state_entry_payload) do
          { "data" => "some data", "version" => 90 }
        end

        it "returns a ok status code" do
          post "/gossip", signed_payload.to_json, { "CONTENT_TYPE" => "application/json" }

          expect(last_response.status).to eq(200)
        end

        it "returns it's own payload back" do
          post "/gossip", signed_payload.to_json, { "CONTENT_TYPE" => "application/json" }

          expect(JSON.parse(last_response.body)).to be_present
        end
      end
    end
  end

  private

  def sign(payload, key)
    Base64.encode64(key.private_encrypt(Digest::SHA256.hexdigest(payload.to_json)))
  end
end
