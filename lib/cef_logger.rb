require 'syslog/logger'
require 'securerandom'
require 'singleton'

class CefLogger
  class << self
    attr_accessor :product, :vendor, :version, :program, :facility,
                  :filtered_keys

    def log(name: '', severity: 6, data: {})
      id =
        SecureRandom.uuid

      extension =
        compile data

      line = [
        'CEF:0',
        vendor,
        product,
        version,
        id,
        escape_header(name),
        severity,
        extension
      ].join('|')

      logger.info line
    end

    def escape_header(value)
      value
        .to_s
        .gsub('|', '\\|')
    end

    def escape_value(value)
      value
        .to_s
        .gsub('\\', '\\\\\\')
        .gsub('=', '\\=')
        .gsub("\n", '\n')
        .gsub("\r", '\r')
    end

    def compile(data)
      case data
      when Hash
        data
          .reject { |key,| filtered_keys.to_a.map(&:to_s).include?(key.to_s) }
          .map { |key, value| "#{key}=#{escape_value(value)}" }
          .join(' ')
      else
        raise "Can't compile non-hashes as extensions for CEF logging!"
      end
    end

    def logger
      @logger ||= Syslog::Logger.new program, facility
    end
  end
end
