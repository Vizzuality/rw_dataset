# frozen_string_literal: true
class User < ActiveHash::Base
  include ActiveModel::Serialization

  fields :user_id, :role, :apps

  def self.authorize_user!(user, dataset_apps, dataset_user_id=nil)
    user_role    = user.role
    user_apps    = user.apps if user.apps.present?
    dataset_apps = dataset_apps.uniq if dataset_apps.present?
    any_apps     = if user_apps.present? && dataset_apps.present? && (user_apps & dataset_apps).any? && user_apps.size > dataset_apps.size && user_apps | dataset_apps == user_apps
                     true
                   elsif user_apps.present? && dataset_apps.present? && user_apps.sort == dataset_apps.sort
                     true
                   else
                     false
                   end

    user_dataset = user.user_id == dataset_user_id if dataset_user_id.present?

    case user_role
    when 'user' then false
    when 'manager'
      if any_apps.present? && (user_dataset || dataset_user_id.blank?)
        true
      else
        false
      end
    when 'admin'
      if any_apps.present?
        true
      else
        false
      end
    when 'superadmin'
      true
    else
      false
    end
  end
end
