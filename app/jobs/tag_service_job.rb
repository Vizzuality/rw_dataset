class TagServiceJob < ApplicationJob
  queue_as :tags

  def perform(object, params_for_adapter)
    TagService.connect_to_service(object, params_for_adapter)
  end
end
