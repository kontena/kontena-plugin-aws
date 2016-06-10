require 'kontena_cli'
require_relative 'kontena/plugin/aws'
require_relative 'kontena/plugin/aws_command'

Kontena::MainCommand.register("aws", "AWS specific commands", Kontena::Plugin::AwsCommand)
