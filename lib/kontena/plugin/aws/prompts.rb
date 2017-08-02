require 'aws-sdk'
module Kontena::Plugin::Aws::Prompts

  def aws_client
    @aws_client ||= Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
  end

  module Common
    def self.included(base)
      base.prepend Defaults
      base.option "--access-key", "ACCESS_KEY", "AWS access key ID", environment_variable: "AWS_ACCESS_KEY_ID"
      base.option "--secret-key", "SECRET_KEY", "AWS secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"
      base.option "--key-pair", "KEY_PAIR", "EC2 key pair name"
      base.option "--region", "REGION", "EC2 Region", environment_variable: "AWS_REGION"
      base.option "--ssh-public-key", "[PATH]", "SSH public key file path"
      base.option "--zone", "ZONE", "EC2 Availability Zone (a,b,c,d,e)"
      base.option "--type", "SIZE", "Instance type"
      base.option "--vpc-id", "VPC ID", "Virtual Private Cloud (VPC) ID (default: default vpc)"
      base.option "--storage", "STORAGE", "Storage size (GiB)"
      base.option "--subnet-id", "SUBNET ID", "VPC option to specify subnet to launch instance into (default: first subnet in vpc/az)"
      base.option "--version", "VERSION", "Define installed Kontena version", default: 'latest'
      base.option "--[no-]associate-public-ip-address", :flag, "Whether to associated public IP in case the VPC defaults to not doing it", default: true, attribute_name: :associate_public_ip
      base.option "--security-groups", "SECURITY GROUPS", "Comma separated list of security groups (names) where the new instance will be attached (default: create grid specific group if not already existing)"
      base.option "--aws-bundled-cert", :flag, "Use CA certificate bundled in AWS SDK", default: false do |bundle|
        Aws.use_bundled_cert! if bundle
      end
    end

    module Defaults
      def default_access_key
        prompt.ask('AWS access key:', echo: false)
      end

      def default_secret_key
        prompt.ask('AWS secret key:', echo: false)
      end

      CREATE_KEYPAIR_TEXT = 'Create new key pair'
      DummyPair = Struct.new(:key_name)

      def default_key_pair
        key_pairs = aws_client.describe_key_pairs.key_pairs
        if key_pairs.empty?
          import_key_pair
        else
          key_pairs << DummyPair.new(CREATE_KEYPAIR_TEXT)
          answer = prompt.select("Choose EC2 key pair:") do |menu|
            key_pairs.each do |key_pair|
              menu.choice key_pair.key_name, key_pair.key_name
            end
          end
          answer == CREATE_KEYPAIR_TEXT ? import_key_pair : answer
        end
      end

      DEFAULT_SSH_KEY_PATH = File.join(Dir.home, '.ssh', 'id_rsa.pub')

      def import_key_pair
        if ssh_public_key
          public_key = File.read(ssh_public_key)
        else
          public_key = prompt.ask('SSH public key: (enter a ssh key in OpenSSH format "ssh-xxx xxxxx key_name")', default: File.exist?(DEFAULT_SSH_KEY_PATH) ? File.read(DEFAULT_SSH_KEY_PATH).strip : '') do |q|
            q.validate /^ssh-rsa \S+ \S+$/
          end
          key_name = public_key[/\A\S+\s+\S+\s+(\S+)\z/, 1]
        end

        prompt.yes?("Import public key '#{key_name}' to AWS?") || exit_with_error('Aborted')
        pair = Kontena::Machine::Aws::KeypairProvisioner.new(access_key, secret_key, region).run!(public_key: public_key, keypair_name: key_name)
        pair.name
      end

      DEFAULT_REGION = 'eu-west-1'

      def default_region_aws_client
        @default_region_aws_client ||= Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: DEFAULT_REGION)
      end

      def default_region
        STDERR.puts("in default_region_common")
        prompt.select("Choose EC2 region:") do |menu|
          i = 1
          default_region_aws_client.describe_regions.regions.sort_by(&:region_name).each do |region|
            menu.choice region.region_name, region.region_name
            menu.default(i) if region.region_name == DEFAULT_REGION
            i += 1
          end
        end
      end

      def default_zone
        prompt.select("Choose EC2 Availability Zone:") do |menu|
          aws_client.describe_availability_zones.availability_zones.sort_by(&:zone_name).select { |z| z.state == 'available' }.each do |zone|
            menu.choice zone.zone_name, zone.zone_name.sub(zone.region_name, '')
          end
        end
      end

      DEFAULT_INSTANCE_TYPE = 't2.small'

      def default_type
        prompt.ask('Instance type:', default: DEFAULT_INSTANCE_TYPE)
      end

      def default_vpc_id
        vpcs = aws_client.describe_vpcs.vpcs
        exit_with_error("Could not find any Virtual Private Cloud (VPC). Please create one in the AWS console first.") if vpcs.size.zero?
        if vpcs.size == 1 && vpcs.first.state == "available"
          puts "Using VPC ID #{pastel.cyan(vpcs.first.vpc_id)}"
          vpcs.first.vpc_id
        else
          prompt.select("Choose Virtual Private Cloud (VPC) ID:") do |menu|
            vpcs.each do |vpc|
              if vpc.state == 'available'
                name = vpc.vpc_id
                name += ' (default)' if vpc.is_default
                menu.choice name, vpc.vpc_id
              end
            end
          end
        end
      end

      DEFAULT_STORAGE = 30

      def default_storage
        prompt.ask('Storage size (GiB):', default: DEFAULT_STORAGE)
      end

      def default_subnet_id
        filters = [
          { name: "vpc-id", values: [vpc_id] },
          { name: "availability-zone", values: [region + zone] }
        ]
        subnets_result = aws_client.describe_subnets(filters: filters)
        subnets = subnets_result.subnets.sort_by(&:cidr_block)
        exit_with_error "Failed to find any subnets" if subnets.empty?
        if subnets.size == 1 && subnets.first.state == "available"
          puts "Using Subnet ID #{pastel.cyan(subnets.first.subnet_id)}"
          subnets.first.subnet_id
        else
          prompt.select("Specify subnet to launch instance into:") do |menu|
            subnets.each do |subnet|
              if subnet.state == 'available'
                menu.choice "#{subnet.subnet_id} (#{subnet.cidr_block})", subnet.subnet_id
              end
            end
          end
        end
      end
    end
  end

  def ask_node
    if self.name.nil?
      nodes = client.get("grids/#{current_grid}/nodes")
      nodes = nodes['nodes'].select{ |n|
        n['labels'] && n['labels'].include?('provider=aws'.freeze)
      }
      raise "Did not find any nodes with label provider=aws" if nodes.size == 0
      prompt.select("Select node:") do |menu|
        nodes.sort_by{ |n| n['node_number'] }.reverse.each do |node|
          initial = node['initial_member'] ? '(initial) ' : ''
          menu.choice "#{node['name']} #{initial}", node['name']
        end
      end
    else
      self.name
    end
  end

  def resolve_region(node)
    STDERR.puts("in resolve_region")
    return nil if node.nil? || node['labels'].nil?
    node['labels'].each do |label|
      tag, value = label.split('=', 2)
      return value if tag == 'region'
    end
  end
end
