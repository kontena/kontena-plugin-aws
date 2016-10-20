require 'aws-sdk'
module Kontena::Plugin::Aws::Prompts

  def ask_aws_access_key
    if self.access_key.nil?
      prompt.ask('AWS access key: ', echo: false)
    else
      self.access_key
    end
  end

  def ask_aws_secret_key
    if self.secret_key.nil?
      prompt.ask('AWS secret key: ', echo: false)
    else
      self.secret_key
    end
  end

  def ask_aws_key_pair(access_key, secret_key, region)
    if self.key_pair.nil?
      prompt.select("Choose EC2 key pair: ") do |menu|
        aws_client = ::Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
        aws_client.describe_key_pairs.key_pairs.each{ |key_pair|
          menu.choice key_pair.key_name, key_pair.key_name
        }
      end
    else
      self.key_pair
    end
  end

  def ask_aws_region(access_key, secret_key, default = 'eu-west-1')
    if self.region.nil?
      prompt.select("Choose EC2 region: ") do |menu|
        aws_client = ::Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: 'eu-west-1')
        i = 1
        aws_client.describe_regions.regions.sort_by{|r| r.region_name }.each{ |region|
          menu.choice region.region_name, region.region_name
          if region.region_name == default
            menu.default i
          end
          i += 1
        }
      end
    else
      self.region
    end
  end

  def ask_aws_az(access_key, secret_key, region)
    if self.zone.nil?
      prompt.select("Choose EC2 Availability Zone: ") do |menu|
        aws_client = ::Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
        aws_client.describe_availability_zones.availability_zones.sort_by{|r| r.zone_name }.each{ |zone|
          if zone.state == 'available'
            menu.choice zone.zone_name, zone.zone_name.sub(zone.region_name, '')
          end
        }
      end
    else
      self.zone
    end
  end

  def ask_aws_vpc(access_key, secret_key, region)
    if self.vpc_id.nil?
      aws_client = ::Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
      vpcs = aws_client.describe_vpcs.vpcs
      return nil if vpcs.size == 0
      if vpcs.size == 1 && vpcs.first.state == "available"
        vpcs.first.vpc_id
      else
        prompt.select("Choose Virtual Private Cloud (VPC) ID: ") do |menu|
          vpcs.each{ |vpc|
            if vpc.state == 'available'
              name = vpc.vpc_id
              name += ' (default)' if vpc.is_default
              menu.choice name, vpc.vpc_id
            end
          }
        end
      end
    else
      self.vpc_id
    end
  end

  def ask_aws_subnet(access_key, secret_key, region, zone, vpc)
    if self.subnet_id.nil?
      aws_client = ::Aws::EC2::Client.new(access_key_id: access_key, secret_access_key: secret_key, region: region)
      subnets_result = aws_client.describe_subnets(filters: [
        { name: "vpc-id", values: [vpc] },
        { name: "availability-zone", values: [zone]}
      ])
      subnets = subnets_result.subnets.sort_by{|s| s.cidr_block}
      return nil if subnets.size == 0
      if subnets.size == 1 && subnets.first.state == "available"
        puts "Using Subnet (#{subnets.first.subnet_id})"
        subnets.first.subnet_id
      else
        prompt.select("Specify subnet to launch instance into: ") do |menu|
          subnets.each{ |subnet|
            if subnet.state == 'available'
              menu.choice "#{subnet.subnet_id} (#{subnet.cidr_block})", subnet.subnet_id
            end
          }
        end
      end
    else
      self.subnet_id
    end
  end

  def ask_aws_instance_type(default = 't2.small')
    if self.type.nil?
      prompt.ask('Instance type: ', default: default)
    else
      self.type
    end
  end

  def ask_aws_storage(default = '30')
    if self.storage.nil?
      prompt.ask('Storage size (GiB): ', default: default)
    else
      self.storage
    end
  end

  def ask_node(token)
    if self.name.nil?
      nodes = client(token).get("grids/#{current_grid}/nodes")
      nodes = nodes['nodes'].select{ |n|
        n['labels'] && n['labels'].include?('provider=aws'.freeze)
      }
      raise "Did not find any nodes with label provider=aws" if nodes.size == 0
      prompt.select("Select node: ") do |menu|
        nodes.sort_by{|n| n['node_number'] }.reverse.each do |node|
          initial = node['initial_member'] ? '(initial) ' : ''
          menu.choice "#{node['name']} #{initial}", node['name']
        end
      end
    else
      self.name
    end
  end
end
