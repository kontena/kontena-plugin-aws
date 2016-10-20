module Kontena::Plugin::Aws::Nodes
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts

    parameter "[NAME]", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY"
    option "--secret-key", "SECRET_KEY", "AWS secret key", environment_variable: "AWS_SECRET_KEY"
    option "--key-pair", "KEY_PAIR", "EC2 Key Pair"
    option "--region", "REGION", "EC2 Region"
    option "--zone", "ZONE", "EC2 Availability Zone"
    option "--vpc-id", "VPC ID", "Virtual Private Cloud (VPC) ID (default: default vpc)"
    option "--subnet-id", "SUBNET ID", "VPC option to specify subnet to launch instance into (default: first subnet in vpc/az)"
    option "--type", "SIZE", "Instance type"
    option "--storage", "STORAGE", "Storage size (GiB)"
    option "--version", "VERSION", "Define installed Kontena version", default: 'latest'
    option "--associate-public-ip-address", :flag, "Whether to associated public IP in case the VPC defaults to not doing it", default: true, attribute_name: :associate_public_ip
    option "--security-groups", "SECURITY GROUPS", "Comma separated list of security groups (names) where the new instance will be attached (default: create grid specific group if not already existing)"

    def execute
      require_api_url
      require_current_grid

      require 'kontena/machine/aws'
      grid = fetch_grid(current_grid)
      access_key = ask_aws_access_key
      secret_key = ask_aws_secret_key
      region = ask_aws_region(access_key, secret_key)
      zone = ask_aws_az(access_key, secret_key, region)
      vpc_id = ask_aws_vpc(access_key, secret_key, region)
      exit_with_error("Could not find any Virtual Private Cloud (VPC). Please create one in the AWS console first.") unless vpc_id
      subnet_id = ask_aws_subnet(access_key, secret_key, region, zone, vpc_id)
      key_pair = ask_aws_key_pair(access_key, secret_key, region)
      type = ask_aws_instance_type
      storage = ask_aws_storage
      provisioner = provisioner(client(require_token), access_key, secret_key, region)
      provisioner.run!(
          master_uri: api_url,
          grid_token: grid['token'],
          grid: current_grid,
          name: name,
          type: type,
          vpc: vpc_id,
          zone: zone,
          subnet: subnet_id,
          storage: storage,
          version: version,
          key_pair: key_pair,
          associate_public_ip: associate_public_ip?,
          security_groups: security_groups
      )
    end

    # @param [String] id
    # @return [Hash]
    def fetch_grid(id)
      client(require_token).get("grids/#{id}")
    end

    # @param [Kontena::Client] client
    # @param [String] access_key
    # @param [String] secret_key
    # @param [String] region
    # @return [Kontena::Machine::Aws::NodeProvisioner]
    def provisioner(client, access_key, secret_key, region)
      Kontena::Machine::Aws::NodeProvisioner.new(client, access_key, secret_key, region)
    end
  end
end
