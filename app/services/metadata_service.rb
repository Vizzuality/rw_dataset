# frozen_string_literal: true
module MetadataService
  class << self
    def populate_dataset(ids, app=nil)
      Connection.populate_dataset(ids, app, 'metadata')
    end
  end
end
