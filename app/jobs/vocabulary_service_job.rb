# frozen_string_literal: true
class VocabularyServiceJob < ApplicationJob
  queue_as :vocabularies

  def perform(object_class, object_id, params_for_tags, params_for_vocabularies)
    VocabularyService.connect_to_service(object_class, object_id, params_for_tags, params_for_vocabularies)
  end
end
