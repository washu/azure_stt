# frozen_string_literal: true

require 'dry-struct'

module AzureSTT
  #
  # Module for the models. Those models use dry-struct.
  #
  # @see https://dry-rb.org/gems/dry-struct/
  #
  module Models
  end

  #
  # Include Dry.Types()
  #
  module Types
    include Dry.Types()
  end
end

require_relative 'models/base'
require_relative 'models/transcription'
require_relative 'models/file'
require_relative 'models/report'
