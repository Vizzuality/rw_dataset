class TagServiceJob < ApplicationJob
  queue_as :tags

  def perform(params_for_adapter)
    TagService.connect_to_service(params_for_adapter)
  end
end
