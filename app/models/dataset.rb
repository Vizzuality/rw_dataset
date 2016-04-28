# == Schema Information
#
# Table name: datasets
#
#  id              :uuid             not null, primary key
#  dateable_id     :uuid
#  dateable_type   :string
#  name            :string
#  format          :integer          default("0")
#  data_path       :string
#  attributes_path :string
#  row_count       :integer
#  status          :integer          default("0")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Dataset < ApplicationRecord
  self.table_name = :datasets

  FORMAT = %w(JSON).freeze
  STATUS = %w(pending saved failed deleted).freeze

  belongs_to :dateable, polymorphic: true

  after_create :update_data_path, if: "dateable_type.include?('JsonConnector')"

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

  private

    def update_data_path
      self.update_attributes(data_path: 'data')
    end
end
