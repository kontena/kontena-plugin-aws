require 'spec_helper'
require 'kontena/plugin/aws_command'

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

  describe '#run' do
    before(:each) do
      allow(subject).to receive(:require_current_grid).and_return('test-grid')
      allow(subject).to receive(:require_api_url).and_return('http://master.example.com')
      allow(subject).to receive(:api_url).and_return('http://master.example.com')
      allow(subject).to receive(:require_token).and_return('12345')
      allow(subject).to receive(:fetch_grid).and_return({})
      allow(subject).to receive(:client).and_return(client)
    end

    it 'raises usage error if no options are defined' do
      expect {
        subject.run([])
      }.to raise_error(Clamp::UsageError)
    end

    it 'passes options to provisioner' do
      options = [
        '--access-key', 'foo',
        '--secret-key', 'bar',
        '--key-pair', 'master-key'
      ]
      expect(subject).to receive(:provisioner).with(client, 'foo', 'bar', 'eu-west-1').and_return(provisioner)
      expect(provisioner).to receive(:run!).with(
        hash_including(key_pair: 'master-key')
      )
      subject.run(options)
    end
  end
end
