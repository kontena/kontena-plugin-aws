class Kontena::Plugin::AwsCommand < Kontena::Command
  subcommand 'master', 'AWS master related commands', load_subcommand('kontena/plugin/aws/master_command')
  subcommand 'node', 'AWS node related commands', load_subcommand('kontena/plugin/aws/node_command')
end
