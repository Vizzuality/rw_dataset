class Dataset < ApplicationRecord
  self.table_name = :datasets
  belongs_to :dateable, polymorphic: true
end
