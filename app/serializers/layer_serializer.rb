# frozen_string_literal: true
class LayerSerializer < ApplicationSerializer
  attributes :dataset, :application, :slug, :name, :default, :provider, :iso, :description, :layerConfig, :legendConfig, :applicationConfig
end
