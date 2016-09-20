module RSpec
  module RedisHelper
    def self.included(rspec)
      rspec.around(:each, redis: true) do |example|
        with_clean_redis do
          example.run
        end
      end
    end

    host = ENV.fetch('REDIS_PORT_6379_TCP_ADDR') { 'localhost' }
    port = ENV.fetch('REDIS_PORT_6379_TCP_PORT') { 6379 }

    CONFIG = { url: "redis://#{host}:#{port}/1/cache" }

    def redis(&block)
      @redis ||= ::Redis.connect(CONFIG)
    end

    def with_clean_redis(&block)
      redis.flushall
      begin
        yield
      ensure
        redis.flushall
      end
    end
  end
end