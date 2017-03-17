require "multijson_schema_generator/core_ext/hash"

module Watchdocs
  module JSON
    class SchemaGenerator
      attr_accessor :enumerables
      attr_reader :merged

      JSON_TYPES = %w(array object number string null boolean).freeze

      def initialize(enumerables)
        @enumerables = enumerables
      end

      def call
        return unless all_elements_valid?
        merge_all
        generate_schema
      end

      private

      def all_elements_valid?
        !enumerables.empty? &&
          enumerables.all? { |e| e.is_a?(Array) || e.is_a?(Hash) }
      end

      def remove_outdated_type
        newest_class = enumerables.last.class
        enumerables.select! { |e| e.is_a?(newest_class) }
      end

      def merge_all
        @merged = if enumerables.first.is_a?(Hash)
                    enumerables.reduce({}, :deep_extended_merge)
                  else
                    enumerables.reduce([], :+)
                  end
      end

      def generate_schema
        schema = { schema: 'http://json-schema.org/draft-04/schema#' }
        if merged.is_a?(Hash)
          schema.merge!(
            type: 'object',
            properties: dig_into_hash(merged),
            required: require_keys(merged.keys)
          )
        else
          schema.merge!(
            type: 'array',
            items: dig_into_array(merged)
          )
        end
        schema
      end

      def dig_into_hash(h, parents = [])
        properties = {}
        h.each_pair do |k, v|
          if v.is_a?(Hash)
            parents << k
            properties[k] = {
              type: 'object',
              properties: dig_into_hash(v, parents),
              required: require_keys(
                v.keys,
                parents: parents
              )
            }
          elsif v.is_a?(Array)
            properties[k] = {
              type: 'array',
              items: dig_into_array(v)
            }
          elsif v.is_a?(String)
            properties[k] = {
              type: get_type(v)
            }
          else
            properties[k] = {
              type: 'string'
            }
          end
        end
        properties
      end

      def dig_into_array(array)
        return if array.empty?
        if array.all? { |a| a.is_a?(Hash) }
          merged = array.reduce({}, :deep_extended_merge)
          {
            type: 'object',
            properties: dig_into_hash(merged),
            required: require_keys(
              merged.keys,
              parents: [],
              hashes: array
            )
          }
        elsif array.all? { |a| a.is_a?(Array) }
          # TODO: Extend functionality here
          # to support array or arrays better
          merged = array.reduce([], :+)
          dig_into_array(merged)
        elsif array.uniq.one?
          { type: get_type(array.first) }
        else
          # TODO: Support mixed arrays
          { type: 'mixed' }
        end
      end

      def require_keys(keys, parents: [], hashes: nil)
        hashes ||= enumerables
        keys.select do |k|
          hashes.all? do |h|
            parent = parents.inject(h) { |hash, key| hash.fetch(key, {}) }
            parent.nil? || parent.empty? || parent.keys.include?(k)
          end
        end
      end

      def get_type(type)
        JSON_TYPES.include?(type) ? type : 'string'
      end
    end
  end
end
