require 'kontena/plugin/aws/prompts'

module Kontena::Plugin::Aws::Nodes
  class RestartCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts
    prepend Kontena::Plugin::Aws::Prompts::Common::Defaults

    parameter "[NAME]", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY_ID"
    option "--secret-key", "SECRET_KEY", "AWS secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"
    option "--region", "REGION", "EC2 Region (default: node's region)", environment_variable: "AWS_REGION", attribute_name: :aws_region
    option "--aws-bundled-cert", :flag, "Use CA certificate bundled in AWS SDK", default: false

    requires_current_master

    def execute
      require_current_grid
      node_name = self.name || ask_node
      @node = client.get("nodes/#{current_grid}/#{node_name}")

      require_relative '../../../machine/aws'
      Aws.use_bundled_cert! if aws_bundled_cert?

      restarter.run!(node_name)
    rescue Seahorse::Client::NetworkingError => ex
      raise ex unless ex.message.match(/certificate verify failed/)
      exit_with_error Kontena::Machine::Aws.ssl_fail_message(aws_bundled_cert?)
    end

    def restarter
      Kontena::Machine::Aws::NodeRestarter.new(access_key, secret_key, aws_region)
    end

    def default_aws_region
      resolve_region(@node) || default_region
    end
  end
end
