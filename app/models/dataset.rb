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
#

class Dataset < ApplicationRecord
  self.table_name = :datasets

  FORMAT = %w(JSON).freeze
  STATUS = %w(pending saved failed deleted).freeze

  belongs_to :dateable, polymorphic: true

  before_save  :merge_tags,        if: "tags_changed?"
  after_save   :call_tags_service, if: "tags_changed?"
  after_create :update_data_path,  if: "dateable_type.include?('JsonConnector')"
  # after_update :call_tags_service, if: "tags_changed?"

  scope :recent, -> { order('updated_at DESC') }
  scope :available, -> { where(status: 1) }

  scope :filter_rest, -> { where(dateable_type: 'RestConnector').includes(:dateable) }
  scope :filter_json, -> { where(dateable_type: 'JsonConnector').includes(:dateable) }

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

  private

    def merge_tags
      self.tags = self.tags.each { |t| t.downcase! }.uniq
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

      TagServiceJob.perform_later(params_for_adapter)
    end
end
