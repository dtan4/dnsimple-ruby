require 'spec_helper'

describe Dnsimple::Client, ".name_servers" do

  subject { described_class.new(api_endpoint: "https://api.zone", username: "user", api_token: "token").name_servers }


  describe "#name_servers" do
    before do
      stub_request(:get, %r[/v1/domains/.+/name_servers$]).
          to_return(read_fixture("nameservers/list/success.http"))
    end

    it "builds the correct request" do
      subject.list("example.com")

      expect(WebMock).to have_requested(:get, "https://api.zone/v1/domains/example.com/name_servers").
                         with(headers: { 'Accept' => 'application/json' })
    end

    it "returns the name servers" do
      expect(subject.name_servers("example.com")).to eq(%w( ns1.dnsimple.com ns2.dnsimple.com ))
    end

    context "when something does not exist" do
      it "raises NotFoundError" do
        stub_request(:get, %r[/v1]).
            to_return(read_fixture("nameservers/notfound-domain.http"))

        expect {
          subject.name_servers("example.com")
        }.to raise_error(Dnsimple::NotFoundError)
      end
    end
  end

  describe "#change" do
    before do
      stub_request(:post, %r[/v1/domains/.+/name_servers$]).
          to_return(read_fixture("nameservers/change/success.http"))
    end

    it "builds the correct request" do
      subject.change("example.com", %w( ns1.example.com ns2.example.com ))

      expect(WebMock).to have_requested(:post, "https://api.zone/v1/domains/example.com/name_servers").
                         with(body: { "name_servers" => { "ns1" => "ns1.example.com", "ns2" => "ns2.example.com" }}).
                         with(headers: { 'Accept' => 'application/json' })
    end

    it "returns the name servers" do
      expect(subject.change("example.com", %w())).to eq(%w( ns1.dnsimple.com ns2.dnsimple.com ))
    end

    context "when something does not exist" do
      it "raises NotFoundError" do
        stub_request(:post, %r[/v1]).
            to_return(read_fixture("nameservers/notfound-domain.http"))

        expect {
          subject.change("example.com", %w())
        }.to raise_error(Dnsimple::NotFoundError)
      end
    end
  end


  describe "#register" do
    before do
      stub_request(:post, %r[/v1/domains/.+/registry_name_servers$]).
          to_return(read_fixture("nameservers/register/success.http"))
    end

    it "builds the correct request" do
      subject.register("example.com", "ns1.example.com", "127.0.0.1")

      expect(WebMock).to have_requested(:post, "https://api.zone/v1/domains/example.com/registry_name_servers").
                             with(body: { "name_server" => { "name" => "ns1.example.com", "ip" => "127.0.0.1" }}).
                             with(headers: { 'Accept' => 'application/json' })
    end

    it "returns nothing" do
      result = subject.register("example.com", "ns1.example.com", "127.0.0.1")

      expect(result).to be_truthy
    end

    context "when the domain does not exist" do
      it "raises NotFoundError" do
        stub_request(:post, %r[/v1]).
            to_return(read_fixture("nameservers/notfound-domain.http"))

        expect {
          subject.register("example.com", "ns1.example.com", "127.0.0.1")
        }.to raise_error(Dnsimple::NotFoundError)
      end
    end
  end

  describe "#deregister" do
    before do
      stub_request(:delete, %r[/v1/domains/.+/registry_name_servers/.+$]).
          to_return(read_fixture("nameservers/deregister/success.http"))
    end

    it "builds the correct request" do
      subject.deregister("example.com", "ns1.example.com")

      expect(WebMock).to have_requested(:delete, "https://api.zone/v1/domains/example.com/registry_name_servers/ns1.example.com").
                             with(headers: { 'Accept' => 'application/json' })
    end

    it "returns nothing" do
      result = subject.deregister("example.com", "ns1.example.com")

      expect(result).to be_truthy
    end

    context "when the domain does not exist" do
      it "raises NotFoundError" do
        stub_request(:delete, %r[/v1]).
            to_return(read_fixture("nameservers/notfound-domain.http"))

        expect {
          subject.deregister("example.com", "ns1.example.com")
        }.to raise_error(Dnsimple::NotFoundError)
      end
    end
  end

end
