require 'configcat/interfaces'
require 'configcat/constants'
require 'concurrent'

module ConfigCat
  class ManualPollingCachePolicy < CachePolicy
    def initialize(config_fetcher, config_cache)
      @_config_fetcher = config_fetcher
      @_config_cache = config_cache
      @_lock = Concurrent::ReadWriteLock.new()
    end

    def get()
      begin
        @_lock.acquire_read_lock()
        config = @_config_cache.get(CONFIG_FILE_NAME)
        return config
      ensure
        @_lock.release_read_lock()
      end
    end

    def force_refresh()
      begin
        configuration_response = @_config_fetcher.get_configuration_json()
        if configuration_response.is_fetched()
          configuration = configuration_response.json()
          begin
            @_lock.acquire_write_lock()
            @_config_cache.set(CONFIG_FILE_NAME, configuration)
          ensure
            @_lock.release_write_lock()
          end
        end
      rescue StandardError => e
        ConfigCat.logger.error("Double-check your SDK Key at https://app.configcat.com/sdkkey.")
        ConfigCat.logger.error "threw exception #{e.class}:'#{e}'"
        ConfigCat.logger.error "stacktrace: #{e.backtrace}"
      end
    end

    def stop()
      # pass
    end
  end
end
