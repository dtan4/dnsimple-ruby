require 'spec_helper'

describe Dnsimple::Client do

  describe "initialization" do
    it "accepts :api_endpoint option" do
      subject = described_class.new(api_endpoint: "https://api.example.com/")
      expect(subject.api_endpoint).to eq("https://api.example.com/")
    end

    it "normalizes :api_endpoint trailing slash" do
      subject = described_class.new(api_endpoint: "https://api.example.com/missing/slash")
      expect(subject.api_endpoint).to eq("https://api.example.com/missing/slash/")
    end

    it "defaults :api_endpoint to production API" do
      subject = described_class.new
      expect(subject.api_endpoint).to eq("https://api.dnsimple.com/")
    end
  end

  describe "authentication" do
    it "uses HTTP authentication if there's a password provided" do
      stub_request(:any, %r[/test])

      subject = described_class.new(username: "user", password: "pass")
      subject.execute(:get, "test", {})

      expect(WebMock).to have_requested(:get, "https://user:pass@api.dnsimple.com/test")
    end

    it "uses header authentication if there's a domain api token provided" do
      stub_request(:any, %r[/test])

      subject = described_class.new(domain_api_token: "domaintoken")
      subject.execute(:get, "test", {})

      expect(WebMock).to have_requested(:get, "https://api.dnsimple.com/test").
                         with { |req| req.headers["X-Dnsimple-Domain-Token"] == "domaintoken" }
    end

    it "uses header authentication if there's an api token provided" do
      stub_request(:any, %r[/test])

      subject = described_class.new(username: "user", api_token: "token")
      subject.execute(:get, "test", {})

      expect(WebMock).to have_requested(:get, "https://api.dnsimple.com/test").
                         with { |req| req.headers["X-Dnsimple-Token"] == "user:token" }
    end

    it "uses HTTP authentication via exchange token if there's an exchange token provided" do
      stub_request(:any, %r[/test])

      subject = described_class.new(username: "user", password: "pass", exchange_token: "exchange-token")
      subject.execute(:get, "test", {})

      expect(WebMock).to have_requested(:get, "https://exchange-token:x-2fa-basic@api.dnsimple.com/test")
    end

    it "raises an error if there's no password or api token provided" do
      subject = described_class.new(username: "user")

      expect {
        subject.execute(:get, "test", {})
      }.to raise_error(Dnsimple::Error, 'A password or API token is required for all API requests.')
    end

    context "when 2FA is required" do
      subject { described_class.new(username: "user", password: "pass") }

      before do
        stub_request(:any, %r[/test]).
            to_return(read_fixture("2fa/error-required.http"))
      end

      it "raises a TwoFactorAuthenticationRequired error" do
        expect {
          subject.execute(:get, "test", {})
        }.to raise_error(Dnsimple::TwoFactorAuthenticationRequired)
      end
    end
  end

  describe "#get" do
    it "delegates to #request" do
      expect(subject).to receive(:execute).with(:get, "path", { foo: "bar" }).and_return(:returned)
      expect(subject.get("path", foo: "bar")).to eq(:returned)
    end
  end

  describe "#post" do
    it "delegates to #request" do
      expect(subject).to receive(:execute).with(:post, "path", { foo: "bar" }).and_return(:returned)
      expect(subject.post("path", foo: "bar")).to eq(:returned)
    end
  end

  describe "#put" do
    it "delegates to #request" do
      expect(subject).to receive(:execute).with(:put, "path", { foo: "bar" }).and_return(:returned)
      expect(subject.put("path", foo: "bar")).to eq(:returned)
    end
  end

  describe "#delete" do
    it "delegates to #request" do
      expect(subject).to receive(:execute).with(:delete, "path", { foo: "bar" }).and_return(:returned)
      expect(subject.delete("path", foo: "bar")).to eq(:returned)
    end
  end

  describe "#execute" do
    subject { described_class.new(username: "user", password: "pass") }

    it "raises RequestError in case of error" do
      stub_request(:get, %r[/foo]).
          to_return(status: [500, "Internal Server Error"])

      expect {
        subject.execute(:get, "foo", {})
      }.to raise_error(Dnsimple::RequestError, "500")
    end
  end

  describe "#request" do
    subject { described_class.new(username: "user", password: "pass") }

    it "performs a request" do
      stub_request(:get, %r[/foo])

      subject.request(:get, 'foo', {})

      expect(WebMock).to have_requested(:get, "https://user:pass@api.dnsimple.com/foo").
                         with(headers: { 'Accept' => 'application/json', 'User-Agent' => "dnsimple-ruby/#{Dnsimple::VERSION}" })
    end

    it "delegates to HTTParty" do
      stub_request(:get, %r[/foo])

      expect(HTTParty).to receive(:get).
                          with("#{subject.api_endpoint}foo",
                               format: :json,
                               basic_auth: { username: "user", password: "pass" },
                               headers: { 'Accept' => 'application/json', 'User-Agent' => "dnsimple-ruby/#{Dnsimple::VERSION}" }
                          ).
                          and_return(double('response', code: 200))

      subject.request(:get, 'foo', {})
    end

    it "properly extracts options from data" do
      expect(HTTParty).to receive(:put).
                          with("#{subject.api_endpoint}foo",
                               format: :json,
                               body: { something: "else" },
                               query: { foo: "bar" },
                               basic_auth: { username: "user", password: "pass" },
                               headers: { 'Accept' => 'application/json', 'User-Agent' => "dnsimple-ruby/#{Dnsimple::VERSION}", "Custom" => "Header" }
                          ).
                          and_return(double('response', code: 200))

      subject.request(:put, 'foo', { something: "else", query: { foo: "bar" }, headers: { "Custom" => "Header" } })
    end
  end

end
