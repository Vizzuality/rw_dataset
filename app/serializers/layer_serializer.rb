# frozen_string_literal: true
class LayerSerializer < ApplicationSerializer
  attributes :id, :dataset, :application, :slug, :name, :default, :provider, :iso, :description, :layerConfig, :legendConfig, :applicationConfig
end
