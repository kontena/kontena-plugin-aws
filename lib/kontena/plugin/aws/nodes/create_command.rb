module Kontena::Plugin::Aws::Nodes
  class CreateCommand < Kontena::Command
    include Kontena::Cli::Common
    include Kontena::Cli::GridOptions
    include Kontena::Plugin::Aws::Prompts

    parameter "[NAME]", "Node name"
    option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY_ID"
    option "--secret-key", "SECRET_KEY", "AWS secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"
    option "--key-pair", "KEY_PAIR", "EC2 Key Pair"
    option "--region", "REGION", "EC2 Region", environment_variable: "AWS_REGION"
    option "--zone", "ZONE", "EC2 Availability Zone (a,b,c,d,e)"
    option "--vpc-id", "VPC ID", "Virtual Private Cloud (VPC) ID (default: default vpc)"
    option "--subnet-id", "SUBNET ID", "VPC option to specify subnet to launch instance into (default: first subnet in vpc/az)"
    option "--type", "SIZE", "Instance type"
    option "--storage", "STORAGE", "Storage size (GiB)"
    option "--count", "COUNT", "How many instances to create"
    option "--version", "VERSION", "Define installed Kontena version", default: 'latest'
    option "--[no-]associate-public-ip-address", :flag, "Whether to associated public IP in case the VPC defaults to not doing it", default: true, attribute_name: :associate_public_ip
    option "--security-groups", "SECURITY GROUPS", "Comma separated list of security groups (names) where the new instance will be attached (default: create grid specific group if not already existing)"

    def execute
      require_api_url
      require_current_grid

      require 'kontena/machine/aws'
      grid = fetch_grid(current_grid)
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
      aws_count = ask_instance_count
      provisioner = provisioner(client(require_token), aws_access_key, aws_secret_key, aws_region)
      provisioner.run!(
          master_uri: api_url,
          grid_token: grid['token'],
          grid: current_grid,
          name: name,
          type: aws_type,
          vpc: aws_vpc_id,
          zone: aws_zone,
          subnet: aws_subnet_id,
          storage: aws_storage,
          version: version,
          key_pair: aws_key_pair,
          count: aws_count,
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

    def ask_instance_count
      if self.count.nil?
        prompt.ask('How many instances?: ', default: 1)
      else
        self.count
      end
    end
  end
end
