# frozen_string_literal: true
class Layer < ActiveHash::Base
  include ActiveModel::Serialization

  fields :dataset, :application, :slug, :name, :default, :provider, :iso, :description, :layerConfig, :legendConfig, :applicationConfig
end
