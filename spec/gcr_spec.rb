require_relative "./spec_helper"

describe GCR do
  subject { described_class }

  describe "#cassette_dir" do
    it "raises if not configured" do
      subject.cassette_dir = nil

      expect {
        subject.cassette_dir
      }.to raise_exception(GCR::ConfigError)
    end

    it "returns cassette dir if configured" do
      expect(subject.cassette_dir).to eq(TMP_DIR)
    end
  end

  describe "#with_cassette" do
    it "records" do
      # Record
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect(Greetings::Client.hello("sue")).to eq("resp 2 — hello sue")

        # with request_id field
        expect(Greetings::Client.hello("joe", "1")).to eq("resp 3 — hello joe")
      end

      # Play
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect {
          Greetings::Client.hello("fred")
        }.to raise_exception(GCR::NoRecording)

        # with request_id field
        expect {
          Greetings::Client.hello("joe", "2")
        }.to raise_exception(GCR::NoRecording)

        GCR.ignore(:requestId)

        expect(Greetings::Client.hello("joe", "2")).to eq("resp 3 — hello joe")
      end
    end
  end

  describe "with_cassette when matchhing in order" do
    before do
      subject.match_in_order
    end

    it 'works when requests match recorded order' do
      Greetings::Client.reset

      # Record
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect(Greetings::Client.hello("bob")).to eq("resp 2 — hello bob")
      end

      # Play
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect(Greetings::Client.hello("bob")).to eq("resp 2 — hello bob")
      end
    end

    it 'throws exception when requests do not match recorded order' do
      Greetings::Client.reset

      # Record
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect(Greetings::Client.hello("sue")).to eq("resp 1 — hello sue")
        expect(Greetings::Client.hello("bob")).to eq("resp 2 — hello bob")
      end

      # Play
      subject.with_cassette("foo") do
        expect(Greetings::Client.hello("bob")).to eq("resp 0 — hello bob")
        expect { Greetings::Client.hello("bob") }.to raise_error(GCR::NoRecording)
      end
    end
  end
end
