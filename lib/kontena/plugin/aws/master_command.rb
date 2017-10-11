class Kontena::Plugin::Aws::MasterCommand < Kontena::Command
  subcommand "create", "Create a new master to AWS", load_subcommand('kontena/plugin/aws/master/create_command')
  subcommand "terminate", "Destroy current master from AWS", load_subcommand('kontena/plugin/aws/master/terminate_command')
end
