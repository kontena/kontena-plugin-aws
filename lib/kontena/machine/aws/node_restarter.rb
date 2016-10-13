require_relative 'common'

module Kontena::Machine::Aws
  class NodeRestarter
    include Common
    include Kontena::Cli::ShellSpinner

    attr_reader :ec2, :api_client

    # @param [String] access_key_id aws_access_key_id
    # @param [String] secret_key aws_secret_access_key
    # @param [String] region
    def initialize(access_key_id, secret_key, region)
      @ec2 = ::Aws::EC2::Resource.new(
        region: region, credentials: ::Aws::Credentials.new(access_key_id, secret_key)
      )
    end

    def run!(name)
      instances = ec2.instances({
        filters: [
          {name: 'tag:Name', values: [name]}
        ]
      })
      abort("Cannot find AWS instance #{name}") if instances.to_a.size == 0
      abort("There are multiple instances with name #{name}") if instances.to_a.size > 1
      instance = instances.first
      if instance
        spinner "Restarting AWS instance #{name.colorize(:cyan)} " do
          instance.reboot(dry_run: false)
        end
      else
        abort "Cannot find instance #{name.colorize(:cyan)} in AWS"
      end
    end
  end
end
