require 'spec_helper'
require 'kontena/plugin/aws_command'

describe Kontena::Plugin::Aws::Master::CreateCommand do

  let(:subject) do
    described_class.new(File.basename($0))
  end

  let(:provisioner) do
    spy(:provisioner)
  end

  describe '#run' do
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
      expect(subject).to receive(:provisioner).with('foo', 'bar', 'eu-west-1').and_return(provisioner)
      expect(provisioner).to receive(:run!).with(
        hash_including(key_pair: 'master-key')
      )
      subject.run(options)
    end
  end
end
