# frozen_string_literal: true
class MetadataSerializer < ApplicationSerializer
  attributes :id, :dataset, :application, :info
end
