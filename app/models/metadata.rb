class Metadata < ActiveHash::Base
  include ActiveModel::Serialization

  fields :dataset, :application, :info
end
