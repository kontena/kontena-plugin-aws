module Kontena
  module Machine
    module Aws
      def ssl_fail_message(used_option = false)
        if used_option
          "AWS SSL certificate verify failed.\n" +
          "You may need to download cacert.pem and set environment variable\n" +
          "SSL_CERT_FILE=/path/to/cacert.pem"
        else
          "AWS SSL certificate verify failed.\n" +
          "Try running the command again with option --aws-bundled-cert"
        end
      end
      module_function :ssl_fail_message
    end
  end
end
require 'aws-sdk'
require 'kontena/machine/random_name'
require 'kontena/machine/cert_helper'
require_relative 'aws/master_provisioner'
require_relative 'aws/node_provisioner'
require_relative 'aws/node_restarter'
require_relative 'aws/node_destroyer'
