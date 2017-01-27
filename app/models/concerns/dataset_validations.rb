# frozen_string_literal: true
module DatasetValidations
  extend ActiveSupport::Concern

  included do
    before_validation(on: [:create, :update]) do
      validate_name
      validate_legend
      validate_vocabularies
      validate_tags
    end

    validates :name, presence: true, on: :create


    private

      def validate_name
        self.errors.add(:name, "must be a valid string") if valid_json?(self.name)
      end

      def validate_legend
        if self.legend.present? && valid_legend?(self.legend.to_json).blank?
          self.errors.add(:legend, 'must be a valid JSON object. Example: {"legend": {"long": "123", "lat": "123", "country": ["pais"], "region": ["barrio"], "date": ["start_date", "end_date"]}}')
        end
      end

      def validate_vocabularies
        if self.vocabularies.present? && valid_vocabulary?(self.vocabularies.to_json).blank?
          self.errors.add(:vocabularies, 'must be a valid JSON object. Example: {"vocabularies": {"my vocabulary": {"tags": ["my tag 1", "my tag 2"]}}}')
        else
          merge_tags if vocabularies.present?
        end
      end

      def validate_tags
        if self.tags.present? && valid_tags?(self.tags.to_json).blank?
          self.errors.add(:tags, 'must be a valid JSON array. Example: {"tags": ["tag 1", "tag 2"]')
        else
          merge_tags if tags.present? && tags_changed?
        end
      end

      def valid_json?(json)
        begin
          JSON.parse(json)
          return true
        rescue JSON::ParserError
          return false
        end
      end

      def valid_legend?(json)
        begin
          json = JSON.parse(json)
          if (json.keys & ['long', 'lat', 'country', 'region', 'date']).size == json.keys.size
            is_valid = []
            is_valid <<  json['long'].is_a?(String)   if json['long'].present?
            is_valid <<  json['lat'].is_a?(String)    if json['lat'].present?
            is_valid <<  json['country'].is_a?(Array) if json['country'].present?
            is_valid <<  json['region'].is_a?(Array)  if json['region'].present?
            is_valid <<  json['date'].is_a?(Array)    if json['date'].present?
            if is_valid.include?(false)
              return false
            else
              return true
            end
          else
            return false
          end
        rescue JSON::ParserError
          return false
        end
      end

      def valid_vocabulary?(json)
        begin
          json = JSON.parse(json)
          is_valid = []
          json.to_a.each do |voc|
            if voc[1].is_a?(Hash) && voc[1]['tags'].present? && voc[1]['tags'].is_a?(Array)
              is_valid << true
            else
              is_valid << false
            end
          end
          if is_valid.include?(false)
            return false
          else
            return true
          end
        rescue JSON::ParserError
          return false
        end
      end

      def valid_tags?(json)
        begin
          json = JSON.parse(json)
          if json.is_a?(Array)
            is_valid = []
            json.each do |tag|
              if tag.is_a?(String)
                is_valid << true
              else
                is_valid << false
              end
            end
            if is_valid.include?(false)
              return false
            else
              return true
            end
          else
            return false
          end
        rescue JSON::ParserError
          return false
        end
      end

      def merge_tags
        composited_tags = self.tags.each { |t| t.downcase! }.uniq
        if self.vocabularies.present?
          self.vocabularies.to_a.each do |voc|
            voc[1]['tags'].each do |tag|
              composited_tags << tag
            end
          end
        end

        self.tags = composited_tags.each { |t| t.downcase! }.uniq
      end
  end

  class_methods do
  end
end
