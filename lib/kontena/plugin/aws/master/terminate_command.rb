module Kontena::Plugin::Aws::Master
  class TerminateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts
    prepend Kontena::Plugin::Aws::Prompts::Common::Defaults

    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY_ID"
    option "--secret-key", "SECRET_KEY", "AWS secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"
    option "--region", "REGION", "EC2 Region (default: node's region)", environment_variable: "AWS_REGION", attribute_name: :aws_region
    option "--force", :flag, "Force remove", default: false, attribute_name: :forced
    option "--aws-bundled-cert", :flag, "Use CA certificate bundled in AWS SDK", default: false

    requires_current_master

    def execute
      require_current_grid

      require_relative '../../../machine/aws'
      Aws.use_bundled_cert! if aws_bundled_cert?

      master_name = config.current_master.name
      master_instance = destroyer.master_instance(master_name)

      confirm_command(master_name) unless forced?

      destroyer.run!(master_name, master_instance)
    rescue Seahorse::Client::NetworkingError => ex
      raise ex unless ex.message.match(/certificate verify failed/)
      exit_with_error Kontena::Machine::Aws.ssl_fail_message(aws_bundled_cert?)
    end

    def destroyer
      Kontena::Machine::Aws::MasterDestroyer.new(client, access_key, secret_key, aws_region)
    end

    def default_aws_region
      resolve_region(@node) || default_region
    end
  end
end

