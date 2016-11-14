# frozen_string_literal: true
class Layer < ActiveHash::Base
  include ActiveModel::Serialization

  fields :id, :dataset, :application, :slug, :name, :default, :provider, :iso, :description, :layerConfig, :legendConfig, :applicationConfig
end
