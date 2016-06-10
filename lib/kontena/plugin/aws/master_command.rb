require_relative 'master/create_command'

class Kontena::Plugin::Aws::MasterCommand < Kontena::Command

  subcommand "create", "Create a new master to AWS", Kontena::Plugin::Aws::Master::CreateCommand

  def execute
  end
end
