# frozen_string_literal: true
class Metadata < ActiveHash::Base
  include ActiveModel::Serialization

  fields :id, :dataset, :application, :info
end
