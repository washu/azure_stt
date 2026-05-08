# frozen_string_literal: true

#
# Top level module for AzureSTT
#
module AzureSTT
  def self.env_true?(value)
    %w[1 true yes on].include?(value.to_s.strip.downcase)
  end
end

require_relative 'azure_stt/version'
require_relative 'azure_stt/configuration'
require_relative 'azure_stt/errors'
require_relative 'azure_stt/client'
require_relative 'azure_stt/models'
require_relative 'azure_stt/parsers'
require_relative 'azure_stt/session'

AzureSTT.configure do |config|
  config.subscription_key = ENV.fetch('SUBSCRIPTION_KEY', nil)
  config.region = ENV.fetch('REGION', 'uscentral')
  config.government = AzureSTT.env_true?(ENV.fetch('GOVERNMENT', 'false'))
  config.private_link = ENV.fetch('PRIVATE_LINK', nil)
  config.ssl_verify_peer = AzureSTT.env_true?(ENV.fetch('SSL_VERIFY_PEER', 'false'))
  config.ssl_ca_file = ENV.fetch('SSL_CA_FILE', nil)
end
