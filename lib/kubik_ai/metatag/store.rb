# frozen_string_literal: true

require "json"
require "fileutils"

module KubikAi
  module Metatag
    # Pending suggestions and runtime status must survive Active Job workers
    # (separate OS processes). Rails.cache is often NullStore or MemoryStore in
    # development, so those values never reach the web process.
    module Store
      DISK_ROOT = "kubik_ai/metatag"

      module_function

      def read(record, namespace)
        key = cache_key(record, namespace)
        return ::Rails.cache.read(key) unless disk_backed?

        read_disk(record, namespace)
      end

      def write(record, namespace, value, expires_in: 24.hours)
        key = cache_key(record, namespace)
        unless disk_backed?
          ::Rails.cache.write(key, value, expires_in: expires_in)
          return value
        end

        write_disk(record, namespace, value)
        value
      end

      def delete(record, namespace)
        key = cache_key(record, namespace)
        ::Rails.cache.delete(key) unless disk_backed?
        delete_disk(record, namespace)
      end

      def disk_backed?
        cache = ::Rails.cache
        cache.is_a?(ActiveSupport::Cache::NullStore) ||
          cache.is_a?(ActiveSupport::Cache::MemoryStore)
      end

      def cache_key(record, namespace)
        "#{namespace}/#{record.class.name}/#{record.id}"
      end

      def disk_path(record, namespace)
        safe_type = record.class.name.gsub("::", "__")
        ::Rails.root.join("tmp", DISK_ROOT, safe_type, record.id.to_s, "#{namespace}.json")
      end

      def read_disk(record, namespace)
        path = disk_path(record, namespace)
        return nil unless path.exist?

        JSON.parse(path.read)
      rescue JSON::ParserError
        nil
      end

      def write_disk(record, namespace, value)
        path = disk_path(record, namespace)
        ::FileUtils.mkdir_p(path.dirname)
        path.write(JSON.generate(value))
      end

      def delete_disk(record, namespace)
        path = disk_path(record, namespace)
        ::File.delete(path) if path.exist?
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
