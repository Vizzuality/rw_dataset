class TagServiceJob < ApplicationJob
  queue_as :tags

  def perform(object, params_for_tags, params_for_topics)
    TagService.connect_to_service(object, params_for_tags, params_for_topics)
  end
end
