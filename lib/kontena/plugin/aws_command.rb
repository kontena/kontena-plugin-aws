require_relative 'aws/master_command'
require_relative 'aws/node_command'

class Kontena::Plugin::AwsCommand < Kontena::Command

  subcommand 'master', 'AWS master related commands', Kontena::Plugin::Aws::MasterCommand
  subcommand 'node', 'AWS node related commands', Kontena::Plugin::Aws::NodeCommand

  def execute
  end
end
