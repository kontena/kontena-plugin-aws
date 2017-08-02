require 'spec_helper'
require 'kontena/plugin/aws_command'
require 'aws-sdk'

describe Kontena::Plugin::Aws::Nodes::CreateCommand do

  let(:subject) do
    described_class.new(File.basename($0))
  end

  let(:provisioner) do
    spy(:provisioner)
  end

  let(:client) do
    spy(:client)
  end

  before(:each) do
    allow(Aws::EC2::Client).to receive(:new).and_return(spy)
  end

  describe '#run' do
    before(:each) do
      allow(subject).to receive(:verify_current_master).and_return(true)
      allow(subject).to receive(:require_current_grid).and_return('test-grid')
      allow(subject).to receive(:require_api_url).and_return('http://master.example.com')
      allow(subject).to receive(:api_url).and_return('http://master.example.com')
      allow(subject).to receive(:fetch_grid).and_return({})
      allow(subject).to receive(:client).and_return(client)
    end

    it 'prompts user if options are missing' do
      expect(subject).to receive(:prompt).at_least(:once).and_return(spy)
      allow(subject).to receive(:provisioner).and_return(provisioner)
      subject.run(%w(--vpc-id abcd --subnet-id abcd --key-pair foo))
    end

    it 'requires current master' do
      expect(subject.class.requires_current_master?).to be_truthy
    end

    it 'passes options to provisioner' do
      options = %w(
        --access-key foo
        --secret-key bar
        --region eu-west-1
        --key-pair master-key
        --vpc-id abcd
        --subnet-id abcd
      )
      expect(subject).to receive(:prompt).at_least(:once).and_return(spy)
      expect(subject).to receive(:provisioner).and_return(provisioner)
      expect(provisioner).to receive(:run!).with(
        hash_including(key_pair: 'master-key')
      )
      subject.run(options)
    end
  end
end
