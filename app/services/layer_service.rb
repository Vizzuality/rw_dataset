# frozen_string_literal: true
module LayerService
  class << self
    def populate_dataset(ids, app=nil)
      Connection.populate_dataset(ids, app, 'layer')
    end
  end
end
