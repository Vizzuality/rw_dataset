module Service
  SERVICE_URL   = ServiceSetting.gateway_url.freeze
  SERVICE_TOKEN = ServiceSetting.auth_token.freeze if ServiceSetting.auth_token.present?
end
