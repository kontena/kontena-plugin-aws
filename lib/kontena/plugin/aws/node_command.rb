class Kontena::Plugin::Aws::NodeCommand < Kontena::Command
  subcommand "create", "Create a new node to AWS", load_subcommand('kontena/plugin/aws/nodes/create_command')
  subcommand "restart", "Restart AWS node", load_subcommand('kontena/plugin/aws/nodes/restart_command')
  subcommand "terminate", "Terminate AWS node", load_subcommand('kontena/plugin/aws/nodes/terminate_command')
end
