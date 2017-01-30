# frozen_string_literal: true
class Vocabulary < ActiveHash::Base
  include ActiveModel::Serialization

  fields :id, :tags, :name, :resource
end
