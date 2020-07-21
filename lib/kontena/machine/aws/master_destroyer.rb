module Kontena
  module Machine
    module Aws
      class MasterDestroyer

        include Kontena::Cli::ShellSpinner

        attr_reader :ec2, :api_client

        # @param [Kontena::Client] api_client Kontena api client
        # @param [String] access_key_id aws_access_key_id
        # @param [String] secret_key aws_secret_access_key
        # @param [String] region
        def initialize(api_client, access_key_id, secret_key, region = 'eu-west-1')
          @api_client = api_client
          @ec2 = ::Aws::EC2::Resource.new(
            region: region,
            credentials: ::Aws::Credentials.new(access_key_id, secret_key)
          )
        end

        def master_instance(name)
          instances = ec2.instances({
            filters: [
              {name: 'tag:Name', values: [name]}
            ]
          })
          abort("Cannot find AWS instance #{name}") if instances.to_a.empty?
          abort("There are multiple instances with name #{name}") if instances.to_a.size > 1
          instances.first
        end

        def run!(name, instance = nil)
          instance ||= master_instance(name)
          if instance
            spinner "Terminating AWS instance #{name.colorize(:cyan)} " do
              instance.terminate
              until instance.reload.state.name.to_s == 'terminated'
                sleep 1
              end
            end
          else
            abort "Cannot find instance #{name.colorize(:cyan)} in AWS"
          end
        end
      end
    end
  end
end

