require 'fileutils'
require 'erb'
require 'open3'
require 'securerandom'
require 'json'

require_relative 'common'

module Kontena::Machine::Aws
  class MasterProvisioner
    include Kontena::Machine::RandomName
    include Kontena::Machine::CertHelper
    include Common
    include Kontena::Cli::Common

    attr_reader :ec2, :http_client, :region

    # @param [String] access_key_id aws_access_key_id
    # @param [String] secret_key aws_secret_access_key
    # @param [String] region
    def initialize(access_key_id, secret_key, region)
      @ec2 = ::Aws::EC2::Resource.new(
        region: region, credentials: ::Aws::Credentials.new(access_key_id, secret_key)
      )
    end

    # @param [Hash] opts
    def run!(opts)
      ssl_cert = nil
      if opts[:ssl_cert]
        abort('Invalid ssl cert') unless File.exists?(File.expand_path(opts[:ssl_cert]))
        ssl_cert = File.read(File.expand_path(opts[:ssl_cert]))
      else
        spinner "Generating a self-signed SSL certificate" do
          ssl_cert = generate_self_signed_cert
        end
      end

      if opts[:ami]
        ami = opts[:ami]
      else
        ami = resolve_ami(region)
        abort('No valid AMI found for region') unless ami
      end
      opts[:vpc] = default_vpc.vpc_id unless opts[:vpc]

      raise "Missing :subnet option" if opts[:subnet].nil?
      subnet = ec2.subnet(opts[:subnet])
      abort('Failed to find subnet!') unless subnet

      name = opts[:name] || generate_name

      userdata_vars = opts.merge(
          ssl_cert: ssl_cert,
          server_name: name.sub('kontena-master-', '')
      )

      security_groups = opts[:security_groups] ?
          resolve_security_groups_to_ids(opts[:security_groups], opts[:vpc]) :
          ensure_security_group(opts[:vpc])

      ec2_instance = ec2.create_instances({
        image_id: ami,
        min_count: 1,
        max_count: 1,
        instance_type: opts[:type],
        key_name: opts[:key_pair],
        user_data: Base64.encode64(user_data(userdata_vars)),
        block_device_mappings: [
          {
            device_name: '/dev/xvda',
            virtual_name: 'Root',
            ebs: {
              volume_size: opts[:storage],
              volume_type: 'gp2'
            }
          }
        ],
        network_interfaces: [
         {
           device_index: 0,
           subnet_id: subnet.subnet_id,
           groups: security_groups,
           associate_public_ip_address: opts[:associate_public_ip],
           delete_on_termination: true
         }
        ]
      }).first
      ec2_instance.create_tags({
        tags: [
          {key: 'Name', value: name}
        ]
      })

      spinner "Creating an AWS instance #{name.colorize(:cyan)} " do
        sleep 1 until ec2_instance.reload.state.name == 'running'
      end
      public_ip = ec2_instance.reload.public_ip_address
      master_version = nil
      if public_ip.nil?
        master_url = "https://#{ec2_instance.private_ip_address}"
        puts "Could not get public IP for the created master, private connect url is: #{master_url}"
      else
        master_url = "https://#{ec2_instance.public_ip_address}"
        Excon.defaults[:ssl_verify_peer] = false
        http_client = Excon.new(master_url, :connect_timeout => 10)
        spinner "Waiting for #{name.colorize(:cyan)} to start " do
          sleep 0.5 until master_running?(http_client)
        end

        spinner "Retrieving Kontena Master version" do
          master_version = JSON.parse(http_client.get(path: '/').body)["version"] rescue nil
        end

        spinner "Kontena Master #{master_version} is now running at #{master_url}"
      end
      data = {
        name: name.sub('kontena-master-', ''),
        public_ip: public_ip,
        code: opts[:initial_admin_code],
        provider: 'aws',
        version: master_version
      }
      if self.respond_to?(:certificate_public_key)
        data[:ssl_certificate] = certificate_public_key(ssl_cert) unless opts[:ssl_cert]
      end

      data
    end

    ##
    # @param [String] vpc_id
    # @return [Array] Security group id in array
    def ensure_security_group(vpc_id)
      group_name = "kontena_master"
      group_id = resolve_security_groups_to_ids(group_name, vpc_id)

      if group_id.empty?
        spinner "Creating AWS security group" do
          sg = create_security_group(group_name, vpc_id)
          group_id = [sg.group_id]
        end
      end
      group_id
    end

    ##
    # creates security_group and authorizes default port ranges
    #
    # @param [String] name
    # @param [String, NilClass] vpc_id
    # @return Aws::EC2::SecurityGroup
    def create_security_group(name, vpc_id = nil)
      sg = ec2.create_security_group({
        group_name: name,
        description: "Kontena Master",
        vpc_id: vpc_id
      })

      sg.authorize_ingress({
        ip_protocol: 'tcp',
        from_port: 443,
        to_port: 443,
        cidr_ip: '0.0.0.0/0'
      })

      sg.authorize_ingress({
        ip_protocol: 'tcp',
        from_port: 22,
        to_port: 22,
        cidr_ip: '0.0.0.0/0'
      })

      sg
    end

    # @return [String]
    def region
      ec2.client.config.region
    end

    def user_data(vars)
      cloudinit_template = File.join(__dir__ , '/cloudinit_master.yml')
      erb(File.read(cloudinit_template), vars)
    end

    def generate_name
      "kontena-master-#{super}-#{rand(1..9)}"
    end

    def master_running?(http_client)
      http_client.get(path: '/').status == 200
    rescue
      false
    end

    def erb(template, vars)
      ERB.new(template, nil, '%<>-').result(
        OpenStruct.new(vars).instance_eval { binding }
      )
    end
  end
end
