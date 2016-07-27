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
#

class Dataset < ApplicationRecord
  self.table_name = :datasets

  FORMAT = %w(JSON).freeze
  STATUS = %w(pending saved failed deleted).freeze

  belongs_to :dateable, polymorphic: true

  before_save  :merge_tags,        if: "tags_changed?"
  before_save  :merge_apps,        if: "application_changed?"
  after_save   :call_tags_service, if: "tags_changed?"
  after_create :update_data_path,  if: "dateable_type.include?('JsonConnector')"

  scope :recent,             -> { order('updated_at DESC') }
  scope :filter_pending,     -> { where(status: 0)         }
  scope :filter_saved,       -> { where(status: 1)         }
  scope :filter_failed,      -> { where(status: 2)         }
  scope :filter_inactives,   -> { where(status: 3)         }
  scope :available,          -> { filter_saved             }

  scope :filter_rest, -> { where(dateable_type: 'RestConnector').includes(:dateable) }
  scope :filter_json, -> { where(dateable_type: 'JsonConnector').includes(:dateable) }
  scope :filter_doc,  -> { where(dateable_type: 'DocConnector').includes(:dateable)  }

  scope :filter_apps, -> (app) { where('application ?| array[:keys]', keys: ["#{app}"]) }

  def format_txt
    FORMAT[format - 0]
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

  def update_layer_info(options)
    data      = options['dataset']['dataset_attributes']['layer_info']
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

    def merge_apps
      self.application = self.application.each { |a| a.downcase! }.uniq
    end

    def update_data_path
      self.update_attributes(data_path: 'data')
    end

    def call_tags_service
      params_for_adapter = {}
      params_for_adapter['taggable_id']   = self.id
      params_for_adapter['taggable_type'] = self.class.name
      params_for_adapter['taggable_slug'] = self.try(:slug)
      params_for_adapter['tags_list']     = tags

      TagServiceJob.perform_later('Dataset', params_for_adapter)
    end
end
