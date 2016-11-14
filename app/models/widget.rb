# frozen_string_literal: true
class Widget < ActiveHash::Base
  include ActiveModel::Serialization

  fields :id, :dataset, :application, :slug, :name, :default, :description, :widgetConfig, :tempalte, :layerId, :source, :sourceUrl, :authors,
         :queryUrl, :status, :published, :verified
end
