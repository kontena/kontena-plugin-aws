module Kontena::Plugin::Aws::Nodes
  class RestartCommand < Clamp::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions

    parameter "NAME", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", required: true
    option "--secret-key", "SECRET_KEY", "AWS secret key", required: true
    option "--region", "REGION", "EC2 Region", default: 'eu-west-1'

    def execute
      require_api_url
      require_current_grid

      require_relative '../../../machine/aws'

      restarter = restarter(access_key, secret_key, region)
      restarter.run!(name)
    end

    def restarter(access_key, secret_key, region)
      Kontena::Machine::Aws::NodeRestarter.new(access_key, secret_key, region)
    end
  end
end
