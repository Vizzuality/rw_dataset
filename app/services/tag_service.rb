# frozen_string_literal: true
require 'uri'

module TagService
  class << self
    def connect_to_service(object_class, options_tags, options_topics)
      body_tag   = { tag:   options_tags   }
      body_topic = { topic: options_topics }

      headers = {}
      headers['Accept']         = 'application/json'
      headers['authentication'] = Service::SERVICE_TOKEN

      url_tags   = "#{Service::SERVICE_URL}/tags"
      url_tags   = URI.decode(url_tags)
      url_topics = "#{Service::SERVICE_URL}/topics"
      url_topics = URI.decode(url_topics)
      method     = 'post'

      hydra = Typhoeus::Hydra.hydra

      tags_request   = ::Typhoeus::Request.new(URI.escape(url_tags),   method: method, headers: headers, body: body_tag)
      topics_request = ::Typhoeus::Request.new(URI.escape(url_topics), method: method, headers: headers, body: body_topic)

      hydra.queue tags_request
      hydra.queue topics_request
      hydra.run
    end
  end
end
