require 'kontena_cli'
require_relative 'kontena/plugin/aws'
require 'kontena/cli/subcommand_loader'

Kontena::MainCommand.register("aws", "AWS specific commands", Kontena::Cli::SubcommandLoader.new('kontena/plugin/aws_command'))
