module Kontena::Plugin::Aws::Nodes
  class TerminateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts

    parameter "[NAME]", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY"
    option "--secret-key", "SECRET_KEY", "AWS secret key", environment_variable: "AWS_SECRET_KEY"
    option "--region", "REGION", "EC2 Region (default: node's region)", environment_variable: "AWS_REGION"
    option "--force", :flag, "Force remove", default: false, attribute_name: :forced

    def execute
      require_api_url
      require_current_grid

      token = require_token
      node_name = self.name || ask_node(token)
      node = client(token).get("grids/#{current_grid}/nodes/#{node_name}")
      aws_access_key = ask_aws_access_key
      aws_secret_key = ask_aws_secret_key
      aws_region = self.region || resolve_or_ask_region(node, aws_access_key, aws_secret_key)

      confirm_command(node_name) unless forced?
      require 'kontena/machine/aws'
      grid = client(require_token).get("grids/#{current_grid}")
      destroyer = destroyer(client(require_token), aws_access_key, aws_secret_key, aws_region)
      destroyer.run!(grid, node_name)
    end

    def destroyer(client, access_key, secret_key, region)
      Kontena::Machine::Aws::NodeDestroyer.new(client, access_key, secret_key, region)
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
