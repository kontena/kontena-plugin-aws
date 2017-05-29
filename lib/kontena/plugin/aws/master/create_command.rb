require 'kontena/plugin/aws/prompts'

module Kontena::Plugin::Aws::Master
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Plugin::Aws::Prompts

    option "--name", "[NAME]", "Set Master name"

    include Kontena::Plugin::Aws::Prompts::Common

    option "--ssl-cert", "SSL CERT", "SSL certificate file (default: generate self-signed cert)"
    option "--vault-secret", "VAULT_SECRET", "Secret key for Vault (default: generate random secret)"
    option "--vault-iv", "VAULT_IV", "Initialization vector for Vault (default: generate random iv)"
    option "--mongodb-uri", "URI", "External MongoDB uri (optional)"

    def execute
      require 'securerandom'
      require 'kontena/machine/aws'

      provisioner.run!(
        name: name,
        type: type,
        vpc: vpc_id,
        zone: zone,
        subnet: subnet_id,
        ssl_cert: ssl_cert,
        storage: storage,
        version: version,
        key_pair: key_pair,
        vault_secret: vault_secret || SecureRandom.hex(24),
        vault_iv: vault_iv || SecureRandom.hex(24),
        mongodb_uri: mongodb_uri,
        associate_public_ip: associate_public_ip?,
        security_groups: security_groups,
        initial_admin_code: SecureRandom.hex(16)
      )
    rescue Seahorse::Client::NetworkingError => ex
      raise ex unless ex.message.match(/certificate verify failed/)
      exit_with_error Kontena::Machine::Aws.ssl_fail_message(aws_bundled_cert?)
    end

    def provisioner
      Kontena::Machine::Aws::MasterProvisioner.new(access_key, secret_key, region)
    end
  end
end
