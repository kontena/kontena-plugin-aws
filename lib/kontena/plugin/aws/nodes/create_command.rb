require 'kontena/plugin/aws/prompts'

module Kontena::Plugin::Aws::Nodes
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts

    parameter "[NAME]", "Node name"

    include Kontena::Plugin::Aws::Prompts::Common

    option "--count", "COUNT", "How many instances to create"

    requires_current_master

    def execute
      require_current_grid
      require_relative '../../../machine/aws'

      grid = fetch_grid(current_grid)
      provisioner.run!(
        master_uri: api_url,
        grid_token: grid['token'],
        grid: current_grid,
        name: name,
        type: type,
        vpc: vpc_id,
        zone: zone,
        subnet: subnet_id,
        storage: storage,
        version: version,
        key_pair: key_pair,
        count: count,
        associate_public_ip: associate_public_ip?,
        security_groups: security_groups
      )
    rescue Seahorse::Client::NetworkingError => ex
      raise ex unless ex.message.match(/certificate verify failed/)
      exit_with_error Kontena::Machine::Aws.ssl_fail_message(aws_bundled_cert?)
    end

    # @param [String] id
    # @return [Hash]
    def fetch_grid(id)
      client.get("grids/#{id}")
    end

    # @param [Kontena::Client] client
    # @param [String] access_key
    # @param [String] secret_key
    # @param [String] region
    # @return [Kontena::Machine::Aws::NodeProvisioner]
    def provisioner
      Kontena::Machine::Aws::NodeProvisioner.new(client, access_key, secret_key, region)
    end

    def default_count
      prompt.ask('How many instances?: ', default: 1)
    end
  end
end
