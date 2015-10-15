require 'active_support/core_ext/hash/indifferent_access'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'minimum-term'

require 'old-maid/local_or_remote_file'

class OldMaid
  module Instance
    attr_reader :config

    def initialize(params = {})
      @mutex = Mutex.new
      @params = params
    end

    def update_contracts
      @mutex.synchronize do
        update_other_contracts
        update_own_contracts
      end
      true
    end

    def contracts_fulfilled?
      @mutex.synchronize do
        i = MinimumTerm::Infrastructure.new(cache_dir)
        i.contracts_fulfilled?
      end
    end

    def config_file
      return File.expand_path(@params[:config_file]) if @params[:config_file]
      File.join(Dir.pwd, 'config', 'old-maid.yml')
    end

    def env
      return @params[:env].to_sym if @params[:env]
      return unless Object.const_defined?('Rails')
      Rails.env.to_sym
    end

    def cache_dir
        return @cache_dir if @cache_dir
        full_path = File.expand_path(config[:contracts_cache_path])
        FileUtils.mkdir_p(full_path)
        @cache_dir = full_path
    end

    def config
        return @config if @config
        full_config = YAML.load_file(config_file).with_indifferent_access
        env_config  = full_config[env]

        raise "No config for environment #{env} found" unless env_config

        # TODO validate it properly
        [:service_name, :contracts_path, :contracts_cache_path].each do |k|
          raise ":#{k} missing in #{full_config.to_json}" unless env_config[k]
        end

        @config = env_config
    end

    private

    def fetch_service_contracts(service_name, config)
      target_dir = File.join(cache_dir, service_name)
      FileUtils.mkdir_p(target_dir)

      contract_files.each do |contract|
        file = File.join(target_dir, contract)
        FileUtils.rm_f(file)

        File.open(file, 'w') do |out|
          out.puts LocalOrRemoteFile.new(config.merge(file: contract)).read
        end
      end
    end

    def update_other_contracts
      services.each do |service_name, config|
        fetch_service_contracts(service_name, config)
      end
    end

    def update_own_contracts
      contract_files.each do |file|
        source_file = File.join(@config[:contracts_path], file)
        target_file = File.join(cache_dir, @config[:service_name], file)
        FileUtils.rm_f(target_file)
        FileUtils.cp(source_file, target_file) if File.exists?(source_file)
      end
    end

    def contract_files
      ['publish.mson', 'consume.mson']
    end

    def services
      if config[:services]
        return config[:services]
      elsif config[:services_file]
        file = LocalOrRemoteFile.new(config[:services_file])
        services = YAML.load(file.read)
        begin
          services.with_indifferent_access
        rescue
          raise "Could not load services from #{config[:services_file].to_json}"
        end
      end
    end

  end
end
