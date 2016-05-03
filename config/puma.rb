# # Change to match your CPU core count
# # workers 1

# # Min and Max threads per worker
# threads 0,5

# rackup DefaultRackup
# # Default to 3000
# port ENV.fetch('RW_DATASET_PORT') { 3000 }
# # Default to production
# environment ENV.fetch('RW_DATASET_ENV') { 'development' }

# daemonize true

# # Set master PID and state locations
# pidfile    'tmp/pids/puma.pid'
# state_path 'tmp/pids/puma.state'

# on_worker_boot do
#   ActiveSupport.on_load(:active_record) do
#     config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
#     config['pool'] = ENV['MAX_THREADS'] || 5
#     ActiveRecord::Base.establish_connection(config)
#   end
# end

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end