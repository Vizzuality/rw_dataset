# frozen_string_literal: true
require 'uri'

module VocabularyService
  class << self
    def populate_dataset(ids, app=nil)
      Connection.populate_dataset(ids, app, 'vocabulary')
    end

    def connect_to_service(object_class, object_id, options_tags, options_vocabularies)
      body_tag          = { legacy: { tags: options_tags } } if options_tags.present?
      body_vocabularies = options_vocabularies               if options_vocabularies.present?

      body = {}
      body = body.merge!(body_vocabularies) if body_vocabularies.present?
      body = body.merge!(body_tag)          if body_tag.present?
      body

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url  = "#{Service::SERVICE_URL}"
      url += "/#{object_class.downcase}/#{object_id}/vocabulary"
      url  = URI.decode(url)

      method = 'post'

      hydra = Typhoeus::Hydra.hydra

      vocabulary_request = ::Typhoeus::Request.new(URI.escape(url), method: method, headers: headers, body: body)
      hydra.queue vocabulary_request
      hydra.run
    end
  end
end
