require_relative 'nodes/create_command'
require_relative 'nodes/restart_command'
require_relative 'nodes/terminate_command'

class Kontena::Plugin::Aws::NodeCommand < Kontena::Command

  subcommand "create", "Create a new node to AWS", Kontena::Plugin::Aws::Nodes::CreateCommand
  subcommand "restart", "Restart AWS node", Kontena::Plugin::Aws::Nodes::RestartCommand
  subcommand "terminate", "Terminate AWS node", Kontena::Plugin::Aws::Nodes::TerminateCommand

  def execute
  end
end
