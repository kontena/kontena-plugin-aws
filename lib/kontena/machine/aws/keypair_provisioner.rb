require_relative 'common'

module Kontena::Machine::Aws
  class KeypairProvisioner

    attr_reader :ec2, :region, :public_key, :keypair_name

    # @param [String] access_key_id aws_access_key_id
    # @param [String] secret_key aws_secret_access_key
    # @param [String] region
    def initialize(access_key_id, secret_key, region)
      @ec2 = ::Aws::EC2::Resource.new(
        region: region, credentials: ::Aws::Credentials.new(access_key_id, secret_key)
      )
    end

    def validate_opts!(opts)
      if opts[:public_key]
        @public_key = opts[:public_key]
      else
        raise "Missing public key"
      end

      @keypair_name = opts[:keypair_name] || "kontena-#{SecureRandom.hex(4)}-#{Time.now.strftime '%Y-%m-%d'}"
    end

    # @param [Hash] opts
    def run!(opts)
      validate_opts!(opts)
      ec2.import_key_pair(
        key_name: keypair_name,
        public_key_material: public_key,
        dry_run: false
      )
    end
  end
end

