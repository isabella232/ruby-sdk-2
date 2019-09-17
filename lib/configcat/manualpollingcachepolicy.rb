require 'configcat/interfaces'
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
        config = @_config_cache.get()
        return config
      ensure
        @_lock.release_read_lock()
      end
    end

    def force_refresh()
      begin
        configuration = @_config_fetcher.get_configuration_json()
        begin
          @_lock.acquire_write_lock()
          @_config_cache.set(configuration)
        ensure
          @_lock.release_write_lock()
        end
      rescue HTTPError => e
        # TODO: logger is needed
        # log.error("Received unexpected response from ConfigFetcher " + e.response.to_s)
      rescue
        # log.exception(sys.exc_info()[0])
      end
    end

    def stop()
      # pass
    end
  end
end
