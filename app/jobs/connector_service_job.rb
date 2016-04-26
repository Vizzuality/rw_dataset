class ConnectorServiceJob < ApplicationJob
  queue_as :default

  def perform(object, params_for_adapter)
    ConnectorService.connect_to_service(object, params_for_adapter)
  end
end
