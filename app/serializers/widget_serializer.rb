# frozen_string_literal: true
class WidgetSerializer < ApplicationSerializer
  attributes :dataset, :application, :slug, :name, :default, :description, :widgetConfig, :tempalte, :layerId, :source, :sourceUrl, :authors,
             :queryUrl, :status, :published, :verified
end
