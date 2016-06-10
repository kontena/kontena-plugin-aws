module Kontena
  module Machine
    module Aws
    end
  end
end

require 'kontena/machine/random_name'
require 'kontena/machine/cert_helper'
require_relative 'aws/master_provisioner'
require_relative 'aws/node_provisioner'
require_relative 'aws/node_destroyer'
