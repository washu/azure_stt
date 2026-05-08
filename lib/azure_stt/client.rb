# frozen_string_literal: true

require 'httparty'
require 'openssl'
module AzureSTT
  #
  # Client class that uses HTTParty to communicate with the API
  #
  class Client
    include HTTParty

    attr_reader :region, :subscription_key, :government, :private_link,
                :ssl_verify_peer, :ssl_ca_file

    #
    # Initialize the client
    #
    # @param [String] subscription_key Cognitive Services API Key
    # @param [String] region The region of your resources
    #
    def initialize(region:, subscription_key:, government: false, private_link: nil,
                   ssl_verify_peer: true, ssl_ca_file: nil)
      @subscription_key = subscription_key
      @region = region
      @government = government
      @private_link = private_link
      @ssl_verify_peer = ssl_verify_peer
      @ssl_ca_file = ssl_ca_file

      base_url = "https://#{region}.api.cognitive.microsoft.#{government ? 'us' : 'com'}"
      base_url = @private_link if value_present?(@private_link)
      self.class.base_uri "#{base_url.chomp('/')}/speechtotext/v3.1"
    end

    #
    # Create a transcription for a batch or a single file.
    #
    # @see https://francecentral.dev.cognitive.microsoft.com/docs/services/speech-to-text-api-v3-1/operations/CreateTranscription
    #
    # @param [Hash] args
    #
    # @return [Hash] The JSON body response, parsed by HTTParty
    #
    def create_transcription(**args)
      results = post(
        '/transcriptions',
        args.to_json
      )

      results.parsed_response
    end

    #
    # Get a transcription by giving it's id
    #
    # @param [String] id The identifier of the transcription
    #
    # @return [Hash] The JSON body response, parsed by HTTParty
    #
    def get_transcription(id)
      results = get("/transcriptions/#{id}")

      results.parsed_response
    end

    #
    # Get an Array of all the transcriptions
    #
    # @param [Integer] skip Number of transcriptions that will be skipped (optional)
    # @param [Integer] top Number of transcriptions that will be included (optional)
    #
    # @return [Array[Hash]] Array of all the transcriptions. The transcriptions
    # are Hashes parsed by HTTParty.
    #
    def get_transcriptions(skip: nil, top: nil)
      results = get(
        '/transcriptions',
        {
          skip: skip,
          top: top
        }.compact
      )

      results.parsed_response['values']
    end

    #
    # Delete a transcription with a given ID
    #
    # @param [String] id The id of the transcription in the API
    #
    # @return [Boolean] true if the transcription had been deleted, raises an error else
    #
    def delete_transcription(id)
      response = with_network_error_handling do
        self.class.delete("/transcriptions/#{id}", request_options(headers: headers))
      end
      handle_response(response)

      true
    end

    #
    # Get an array containing the files for a given transcription
    #
    # @see https://uscentral.dev.cognitive.microsoft.com/docs/services/speech-to-text-api-v3-1/operations/GetTranscriptionFiles
    #
    # @param [Integer] id The identifier of the transcription
    #
    # @return [Array[Hash]] Array of the files of a transcription
    #
    def get_transcription_files(id)
      results = get("/transcriptions/#{id}/files")

      results.parsed_response['values']
    end

    #
    # Read a JSON file and parse it.
    #
    # @param [String] file_url The url of the content
    #
    # @return [Hash] the file parsed
    #
    def get_file(file_url)
      response = with_network_error_handling do
        HTTParty.get(file_url, request_options)
      end

      results = handle_response(response)

      results.parsed_response
    end

    private

    #
    # Make a post request by giving a path and a body
    #
    # @param [String] path the path, which is added to the base_uri
    # @param [String] body the body of the request
    #
    # @return [HTTParty::Response]
    #
    def post(path, body)
      response = with_network_error_handling do
        self.class.post(path, request_options(headers: headers, body: body))
      end
      handle_response(response)
    end

    #
    # Make a get request to the API.
    #
    # @param [String] path the path, which is added to the base_uri
    # @param [Hash] parameters The parameters you want to add to the headers (empty by default)
    #
    # @return [HTTParty::Response]
    #
    def get(path, parameters = nil)
      response = with_network_error_handling do
        self.class.get(path, request_options(headers: headers, query: parameters))
      end
      handle_response(response)
    end

    def request_options(headers: nil, query: nil, body: nil)
      {
        headers: headers,
        query: query,
        body: body
      }.merge(ssl_options).compact
    end

    def ssl_options
      return { verify: false } unless ssl_verify_peer

      {
        verify: true,
        ssl_ca_file: value_present?(ssl_ca_file) ? ssl_ca_file : nil
      }.compact
    end

    def with_network_error_handling
      yield
    rescue OpenSSL::SSL::SSLError => e
      raise NetError.new(
        code: 0,
        message: "SSL connection failed: #{e.message}. " \
                 'Set ssl_verify_peer: false for private endpoints with mismatched certificates, or set ssl_ca_file to trust your private CA.'
      )
    end

    #
    # Handle the HTTParty::Response. If an error occured, an exception will be
    # raised.
    #
    # @param [HTTParty] response The response received from the API
    #
    # @return [<Type>] <description>
    #
    # @raise [ServiceError] if an error occured from the API, for instance if
    # subscription_key is invalid.
    #
    # @raise [NetError] if the server has not been reached
    #
    def handle_response(response)
      case response.code
      when 200..299
        response
      else
        if response.request.format == :json
          raise ServiceError.new(
            code: response.code,
            message: response['code'] || response.message,
            azure_message: response['message'] || response.dig('error', 'message')
          )
        else
          raise NetError.new(
            code: response.code,
            message: response.message
          )
        end
      end
    end

    #
    # The header needed to make a request
    #
    # @return [Hash]
    #
    def headers
      {
        'Ocp-Apim-Subscription-Key' => subscription_key,
        'Content-Type' => 'application/json'
      }
    end

    def value_present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end
  end
end
