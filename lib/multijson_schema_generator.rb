require "multijson_schema_generator/version"

class Hash
  def deep_merge!(other_hash)
    other_hash.each_pair do |current_key, other_value|
      this_value = self[current_key]

      self[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
        this_value.deep_merge(other_value)
      elsif this_value.is_a?(Array) && other_value.is_a?(Array)
        this_value + other_value
      else
        other_value || this_value
      end
    end
    self
  end

  def deep_merge(other_hash)
    dup.deep_merge!(other_hash)
  end
end

class Object
  def json_data_type
    if is_a?(Numeric)
      'number'
    elsif is_a?(NilClass)
      'null'
    elsif is_a?(String)
      'string'
    elsif is_a?(TrueClass) || is_a?(FalseClass)
      'boolean'
    else
      '*****'
    end
  end
end

module MultijsonSchemaGenerator
  class << self
    def generate(hashes = [])
      @hashes = hashes
      merged = hashes.reduce({}, :deep_merge)
      return unless merged.is_a?(Hash)

      {
        schema: 'http://json-schema.org/draft-04/schema#',
        properties: properties(merged),
        type: 'object',
        required: required(merged.keys)
      }
    end

    def properties(h, parents = [])
      properties = {}
      h.each_pair do |k, v|
        if v.is_a?(Hash)
          parents << k
          properties[k] = {
            type: 'object',
            properties: properties(v, parents),
            required: required(
              v.keys,
              parents: parents
            )
          }
        elsif v.is_a?(Array)
          properties[k] = {
            type: 'array',
            items: array_items(v)
          }
        elsif non_enumerable_json_type?(v)
          properties[k] = {
            type: v.json_data_type
          }
        else
          properties[k] = {
            type: 'unknown'
          }
        end
      end
      properties
    end

    def array_items(array)
      return if array.empty?
      if array.all? { |a| a.is_a?(Hash) }
        merged = array.reduce({}, :deep_merge)
        {
          type: 'object',
          properties: properties(merged),
          required: required(
            merged.keys,
            parents:[],
            hashes: array
          )
        }
      elsif array.all? { |a| a.is_a?(Array) }
        merged = array.reduce([], :+)
        array_items(merged)
      elsif all_of_the_same_json_type?(array)
        { type: array.first.json_data_type }
      else
        { type: 'mixed' }
      end
    end

    def required(keys, parents: [], hashes: nil)
      hashes ||= @hashes
      keys.select do |k|
        hashes.all? do |h|
          parent = parents.inject(h) { |hash, key| hash.fetch(key, {}) }
          parent.nil? || parent.empty? || parent.keys.include?(k)
        end
      end
    end

    def non_enumerable_json_type?(v)
      v.is_a?(String) ||
        v.is_a?(Numeric) ||
        v.is_a?(TrueClass) ||
        v.is_a?(FalseClass) ||
        v.is_a?(NilClass)
    end

    def all_of_the_same_json_type?(array)
      array.all? { |a| a.is_a?(String) } ||
        array.all? { |a| a.is_a?(Numeric) } ||
        array.all? { |a| a.is_a?(TrueClass) || a.is_a?(FalseClass) } ||
        array.all? { |a| a.is_a?(NilClass) }
    end
  end
end
