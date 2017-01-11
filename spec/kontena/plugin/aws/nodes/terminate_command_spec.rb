require 'spec_helper'
require 'kontena/plugin/aws_command'
require 'aws-sdk'
describe Kontena::Plugin::Aws::Nodes::TerminateCommand do

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
      allow(subject).to receive(:verify_current_master).and_return(true)
      allow(subject).to receive(:require_current_grid).and_return('test-grid')
      allow(subject).to receive(:require_api_url).and_return('http://master.example.com')
      allow(subject).to receive(:api_url).and_return('http://master.example.com')
      allow(subject).to receive(:grid).and_return({})
      allow(subject).to receive(:client).and_return(client)
      allow(Aws::EC2::Client).to receive(:new).and_return(spy)
    end

    it 'raises usage error if no options are defined' do
      allow(subject).to receive(:destroyer).and_return(provisioner)
      expect(subject).to receive(:prompt).at_least(:once).and_return(spy)
      subject.run([])
    end

    it 'requires current master' do
      expect(subject.class.requires_current_master?).to be_truthy
    end

    it 'passes options to provisioner' do
      options = [
        '--access-key', 'foo',
        '--secret-key', 'bar',
        '--region', 'eu-west-1',
        '--force',
        'my-node'
      ]
      expect(subject).to receive(:destroyer).with('foo', 'bar', 'eu-west-1').and_return(provisioner)
      expect(provisioner).to receive(:run!)
      subject.run(options)
    end
  end
end
