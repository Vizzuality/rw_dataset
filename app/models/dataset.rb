# frozen_string_literal: true
# == Schema Information
#
# Table name: datasets
#
#  id              :uuid             not null, primary key
#  dateable_id     :uuid
#  dateable_type   :string
#  name            :string
#  format          :integer          default(0)
#  data_path       :string
#  attributes_path :string
#  row_count       :integer
#  status          :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tags            :jsonb
#  application     :jsonb
#  layer_info      :jsonb
#  data_overwrite  :boolean          default(FALSE)
#  subtitle        :string
#  topics          :jsonb
#  user_id         :string
#

class Dataset < ApplicationRecord
  self.table_name = :datasets

  FORMAT = %w(JSON).freeze
  STATUS = %w(pending saved failed deleted).freeze

  attr_accessor :metadata

  belongs_to :dateable, polymorphic: true

  before_save  :merge_tags,        if: "tags.present? && tags_changed?"
  before_save  :merge_topics,      if: "topics.present? && topics_changed?"
  before_save  :merge_apps,        if: "application.present? && application_changed?"
  after_save   :call_tags_service, if: "tags_changed? || topics_changed?"
  after_save   :clear_cache
  after_create :update_data_path,  if: "data_path.blank? && dateable_type.include?('JsonConnector')"

  scope :recent,             -> { order('updated_at DESC') }
  scope :including_dateable, -> { includes(:dateable)      }
  scope :filter_pending,     -> { where(status: 0)         }
  scope :filter_saved,       -> { where(status: 1)         }
  scope :filter_failed,      -> { where(status: 2)         }
  scope :filter_inactives,   -> { where(status: 3)         }
  scope :available,          -> { filter_saved             }

  scope :filter_rest, -> { where(dateable_type: 'RestConnector').includes(:dateable) }
  scope :filter_json, -> { where(dateable_type: 'JsonConnector').includes(:dateable) }
  scope :filter_doc,  -> { where(dateable_type: 'DocConnector').includes(:dateable)  }
  scope :filter_wms,  -> { where(dateable_type: 'WmsConnector').includes(:dateable)  }

  scope :filter_apps, ->(app) { where('application ?| array[:keys]', keys: ["#{app}"]) }

  def format_txt
    FORMAT[format - 0]
  end

  def dateable_type_txt
    case dateable_type
    when 'JsonConnector' then 'json'
    when 'DocConnector'  then 'document'
    when 'WmsConnector'  then 'wms'
    else
      'rest'
    end
  end

  def status_txt
    STATUS[status - 0]
  end

  def deleted?
    status_txt == 'deleted'
  end

  def saved?
    status_txt == 'saved'
  end

  def populate(includes_meta, app)
    includes_meta = includes_meta.split(',') if includes_meta.present?

    includes_meta.each do |include|
      case include
      when 'metadata'
        Metadata.data = MetadataService.populate_dataset(self.id, app)
        @metadata     = Metadata.where(dataset: self.id)
      end
    end
  end

  def update_layer_info(options)
    data      = options['dataset']['layer_info']
    layer_obj = self.layer_info.find { |l| l['layer_id'] == data['layer_id'] && l['application'] == data['application'] }

    layer_info_data = if layer_info.any? && layer_obj.present?
                        data       = layer_obj.merge(data)
                        layer_info = self.layer_info.delete_if { |l| l['layer_id'] == data['layer_id'] && l['application'] == data['application'] }
                        layer_info.inject([data], :<<)
                      elsif layer_obj.blank?
                        self.layer_info.inject([data], :<<)
                      else
                        [data]
                      end

    update(layer_info: layer_info_data)
  end

  private

    def merge_tags
      self.tags = self.tags.each { |t| t.downcase! }.uniq
    end

    def merge_topics
      self.topics = self.topics.each { |t| t.downcase! }.uniq
    end

    def merge_apps
      self.application = self.application.each { |a| a.downcase! }.uniq
    end

    def update_data_path
      self.update_attributes(data_path: 'data')
    end

    def clear_cache
      Rails.cache.delete_matched('*datasets_*')
    end

    def call_tags_service
      params_for_tags = {}
      params_for_tags['taggable_id']    = self.id
      params_for_tags['taggable_type']  = self.class.name
      params_for_tags['taggable_slug']  = self.try(:slug)
      params_for_tags['tags_list']      = tags

      params_for_topics = {}
      params_for_topics['topicable_id']   = params_for_tags['taggable_id']
      params_for_topics['topicable_type'] = params_for_tags['taggable_type']
      params_for_topics['topicable_slug'] = params_for_tags['taggable_slug']
      params_for_topics['topics_list']    = topics

      TagServiceJob.perform_later('Dataset', params_for_tags, params_for_topics)
    end
end
