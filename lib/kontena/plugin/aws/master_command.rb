require_relative 'master/create_command'
require_relative 'master/terminate_command'

class Kontena::Plugin::Aws::MasterCommand < Kontena::Command

  subcommand "create", "Create a new master to AWS", Kontena::Plugin::Aws::Master::CreateCommand
  subcommand "terminate", "Destroy current master from AWS", Kontena::Plugin::Aws::Master::TerminateCommand

  def execute
  end
end
