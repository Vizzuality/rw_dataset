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

  # enum status: { pending: 0, saved: 1, failed: 2, deleted: 3 }

  FORMAT = %w(JSON).freeze
  STATUS = %w(pending saved failed deleted).freeze

  attr_accessor :metadata, :layer, :widget

  belongs_to :dateable, polymorphic: true
  belongs_to :rest_connector, -> { where("datasets.dateable_type = 'RestConnector'") }, foreign_key: :dateable_id, optional: true
  belongs_to :json_connector, -> { where("datasets.dateable_type = 'JsonConnector'") }, foreign_key: :dateable_id, optional: true
  belongs_to :doc_connector,  -> { where("datasets.dateable_type = 'DocConnector'")  }, foreign_key: :dateable_id, optional: true
  belongs_to :wms_connector,  -> { where("datasets.dateable_type = 'WmsConnector'")  }, foreign_key: :dateable_id, optional: true

  before_save  :merge_tags,        if: 'tags.present? && tags_changed?'
  before_save  :merge_topics,      if: 'topics.present? && topics_changed?'
  before_save  :merge_apps,        if: 'application.present? && application_changed?'
  after_save   :call_tags_service, if: 'tags_changed? || topics_changed?'
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

  class << self
    def fetch_all(options)
      connector_type = options['connector_type'].downcase if options['connector_type'].present?
      status         = options['status'].downcase         if options['status'].present?
      app            = options['app'].downcase            if options['app'].present?
      including      = options['includes']                if options['includes'].present?
      provider       = options['provider']                if options['provider'].present?
      page_number    = options['page']['number']          if options['page'].present? && options['page']['number'].present?
      page_size      = options['page']['size']            if options['page'].present? && options['page']['size'].present?
      sort           = options['sort']                    if options['sort'].present?

      cache_options  = 'list'
      cache_options += "_#{connector_type}"          if connector_type.present?
      cache_options += "_status:#{status}"           if status.present?
      cache_options += "_app:#{app}"                 if app.present?
      cache_options += "_includes:#{including}"      if including.present?
      cache_options += "_page_number:#{page_number}" if page_number.present?
      cache_options += "_page_size:#{page_size}"     if page_size.present?
      cache_options += "_sort:#{sort}"               if sort.present?

      if datasets = Rails.cache.read(cache_key(cache_options))
        datasets
      else
        datasets = Dataset.includes(:dateable).recent

        datasets = case connector_type
                   when 'rest'                 then datasets.filter_rest.recent
                   when 'json'                 then datasets.filter_json.recent
                   when ('doc' || 'document')  then datasets.filter_doc.recent
                   when 'wms'                  then datasets.filter_wms.recent
                   else
                     datasets
                   end

        datasets = if status.present?
                     status_filter(datasets, status)
                   else
                     datasets.available
                   end

        datasets = app_filter(datasets, app)           if app.present?
        datasets = provider_filter(datasets, provider) if provider.present?

        datasets = includes_filter(datasets, including, app) if including.present? && datasets.any?

        Rails.cache.write(cache_key(cache_options), datasets.to_a)
      end
      datasets
    end

    def status_filter(scope, status)
      datasets = scope
      datasets = case status
                 when 'pending'  then datasets.filter_pending
                 when 'active'   then datasets.filter_saved
                 when 'failed'   then datasets.filter_failed
                 when 'disabled' then datasets.filter_inactives
                 when 'all'      then datasets
                 else
                   datasets.available
                 end

      datasets
    end

    def includes_filter(scope, including, applications)
      datasets    = scope
      dataset_ids = datasets.to_a.pluck(:id)
      including   = including.split(',') if including.present?
      app         = applications         if applications.present? && !applications.include?('all')
      if app.present? && app.include?(',')
        app = app.split(',')
      end

      including.each do |include|
        case include
        when 'metadata'
          Metadata.data = MetadataService.populate_dataset(dataset_ids, app)
          datasets = datasets.each do |dataset|
                       dataset.metadata = Metadata.where(dataset: dataset.id)
                     end
        when 'layer'
          Layer.data = LayerService.populate_dataset(dataset_ids, app)
          datasets = datasets.each do |dataset|
                       dataset.layer = Layer.where(dataset: dataset.id)
                     end
        when 'widget'
          Widget.data = WidgetService.populate_dataset(dataset_ids, app)
          datasets = datasets.each do |dataset|
                       dataset.widget = Widget.where(dataset: dataset.id)
                     end
        end
      end

      datasets
    end

    def app_filter(scope, app)
      datasets = scope
      datasets = if app.present? && !app.include?('all')
                   datasets.filter_apps(app)
                 else
                   datasets.available
                 end

      datasets
    end

    def provider_filter(scope, provider)
      datasets = scope
      datasets = if provider.present? && !provider.include?('all')
                   datasets.filter_providers(provider)
                 else
                   datasets.available
                 end

      datasets
    end

    def filter_providers(provider)
      provider_value = case provider
                       when 'cartodb'        then 0
                       when 'featureservice' then 1
                       when 'rwjson'         then 0
                       when 'csv'            then 0
                       when 'wms'            then 0
                       else
                         nil
                       end

      case provider
      when 'cartodb', 'featureservice'
        joins(:rest_connector).where('rest_connectors.connector_provider = ?', provider_value)
      when 'rwjson' then joins(:json_connector).where('json_connectors.connector_provider = ?', provider_value)
      when 'csv'    then joins(:doc_connector).where('doc_connectors.connector_provider = ?', provider_value)
      when 'wms'    then joins(:wms_connector).where('wms_connectors.connector_provider = ?', provider_value)
      else
        []
      end
    end

    def cache_key(cache_options)
      "datasets_#{ cache_options }"
    end
  end

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

  def populate(includes, applications)
    includes = includes.split(',') if includes.present?
    app      = applications        if applications.present? && !applications.include?('all')
    if app.present? && app.include?(',')
      app = app.split(',')
    end

    includes.each do |include|
      case include
      when 'metadata'
        Metadata.data = MetadataService.populate_dataset(self.id, app)
        @metadata     = Metadata.where(dataset: self.id)
      when 'layer'
        Layer.data = LayerService.populate_dataset(self.id, app)
        @layer     = Layer.where(dataset: self.id)
      when 'widget'
        Widget.data = WidgetService.populate_dataset(self.id, app)
        @widget     = Widget.where(dataset: self.id)
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
