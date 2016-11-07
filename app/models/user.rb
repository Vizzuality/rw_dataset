# frozen_string_literal: true
class User < ActiveHash::Base
  fields :user_id, :role, :apps

  class << self
    def authorize_user!(user, dataset_apps, dataset_user_id=nil)
      user_role    = user.role
      user_apps    = user.apps if user.apps.present?
      dataset_apps = dataset_apps.uniq if dataset_apps.present?
      first_case   = user_apps.present? && dataset_apps.present? &&
                                        (user_apps & dataset_apps).any? &&
                                        user_apps.size > dataset_apps.size &&
                                        user_apps | dataset_apps == user_apps
      second_case  = user_apps.present? && dataset_apps.present? &&
                                        user_apps.sort == dataset_apps.sort
      any_apps     = if first_case
                       true
                     elsif second_case
                       true
                     else
                       false
                     end

      user_dataset = user.user_id == dataset_user_id if dataset_user_id.present?

      case user_role
      when 'user' then false
      when 'manager'
        manager_ability(any_apps, user_dataset, dataset_user_id)
      when 'admin'
        admin_ability(any_apps)
      when 'superadmin'
        true
      else
        false
      end
    end

    def manager_ability(any_apps, user_dataset, dataset_user_id)
      if any_apps.present? && (user_dataset || dataset_user_id.blank?)
        true
      else
        false
      end
    end

    def admin_ability(any_apps)
      if any_apps.present?
        true
      else
        false
      end
    end
  end
end
