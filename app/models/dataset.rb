class Dataset < ApplicationRecord
  self.table_name = :datasets
  belongs_to :dateable, polymorphic: true

  scope :recent, -> { order('updated_at DESC') }

  scope :filter_rest, -> { where(dateable_type: 'RestConnector').includes(:dateable) }
  scope :filter_json, -> { where(dateable_type: 'JsonConnector').includes(:dateable) }
end
