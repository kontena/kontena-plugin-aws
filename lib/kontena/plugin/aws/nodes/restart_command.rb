module Kontena::Plugin::Aws::Nodes
  class RestartCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts

    parameter "[NAME]", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY_ID"
    option "--secret-key", "SECRET_KEY", "AWS secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"
    option "--region", "REGION", "EC2 Region", environment_variable: "AWS_REGION"

    requires_current_master

    def execute
      require_current_grid
      node_name = self.name || ask_node
      node = client.get("grids/#{current_grid}/nodes/#{node_name}")

      aws_access_key = ask_aws_access_key
      aws_secret_key = ask_aws_secret_key
      aws_region = self.region || resolve_or_ask_region(node, aws_access_key, aws_secret_key)
      require_relative '../../../machine/aws'

      restarter = restarter(aws_access_key, aws_secret_key, aws_region)
      restarter.run!(node_name)
    end

    def restarter(access_key, secret_key, region)
      Kontena::Machine::Aws::NodeRestarter.new(access_key, secret_key, region)
    end

    def resolve_or_ask_region(node, access_key, secret_key)
      if node['labels'] && region_label = node['labels'].find{ |l| l.split('=').first == 'region' }
        region = region_label.split('=').last
      end
      region = ask_aws_region(access_key, secret_key) unless region
      region
    end
  end
end
