require 'securerandom'
require_relative '../prompts'

module Kontena::Plugin::Aws::Master
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Plugin::Aws::Prompts

    option "--name", "[NAME]", "Set Master name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY"
    option "--secret-key", "SECRET_KEY", "AWS secret key", environment_variable: "AWS_SECRET_KEY"
    option "--key-pair", "KEY_PAIR", "EC2 key pair name"
    option "--ssl-cert", "SSL CERT", "SSL certificate file (default: generate self-signed cert)"
    option "--region", "REGION", "EC2 Region", environment_variable: "AWS_REGION"
    option "--zone", "ZONE", "EC2 Availability Zone (a,b,c,d)"
    option "--vpc-id", "VPC ID", "Virtual Private Cloud (VPC) ID"
    option "--subnet-id", "SUBNET ID", "VPC option to specify subnet to launch instance into (default: first subnet in vpc/az)"
    option "--type", "SIZE", "Instance type"
    option "--storage", "STORAGE", "Storage size (GiB)"
    option "--vault-secret", "VAULT_SECRET", "Secret key for Vault (default: generate random secret)"
    option "--vault-iv", "VAULT_IV", "Initialization vector for Vault (default: generate random iv)"
    option "--mongodb-uri", "URI", "External MongoDB uri (optional)"
    option "--version", "VERSION", "Define installed Kontena version", default: 'latest'
    option "--associate-public-ip-address", :flag, "Whether to associated public IP in case the VPC defaults to not doing it", default: true, attribute_name: :associate_public_ip
    option "--security-groups", "SECURITY_GROUPS", "Comma separated list of security groups (names) where the new instance will be attached (default: create 'kontena_master' group if not already existing)"

    def execute
      require 'kontena/machine/aws'
      aws_access_key = ask_aws_access_key
      aws_secret_key = ask_aws_secret_key
      aws_region = ask_aws_region(aws_access_key, aws_secret_key)
      aws_zone = ask_aws_az(aws_access_key, aws_secret_key, aws_region)
      aws_vpc_id = ask_aws_vpc(aws_access_key, aws_secret_key, aws_region)

      exit_with_error("Could not find any Virtual Private Cloud (VPC). Please create one in the AWS console first.") unless aws_vpc_id
      aws_subnet_id = ask_aws_subnet(aws_access_key, aws_secret_key, aws_region, aws_zone, aws_vpc_id)
      aws_key_pair = ask_aws_key_pair(aws_access_key, aws_secret_key, aws_region)
      aws_type = ask_aws_instance_type
      aws_storage = ask_aws_storage
      provisioner = provisioner(aws_access_key, aws_secret_key, aws_region)
      provisioner.run!(
          name: name,
          type: aws_type,
          vpc: aws_vpc_id,
          zone: aws_zone,
          subnet: aws_subnet_id,
          ssl_cert: ssl_cert,
          storage: aws_storage,
          version: version,
          key_pair: aws_key_pair,
          vault_secret: vault_secret || SecureRandom.hex(24),
          vault_iv: vault_iv || SecureRandom.hex(24),
          mongodb_uri: mongodb_uri,
          associate_public_ip: associate_public_ip?,
          security_groups: security_groups,
          initial_admin_code: SecureRandom.hex(16)
      )
    end

    def provisioner(access_key, secret_key, region)
      Kontena::Machine::Aws::MasterProvisioner.new(access_key, secret_key, region)
    end
  end
end
