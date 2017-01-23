# frozen_string_literal: true
module WidgetService
  class << self
    def populate_dataset(ids, app=nil)
      Connection.populate_dataset(ids, app, 'widget')
    end
  end
end
