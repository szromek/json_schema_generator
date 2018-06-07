require "json_schema_generator/core_ext/hash"

module JsonSchemaGenerator
  def self.generate(object)
    schema = { schema: 'http://json-schema.org/draft-04/schema#' }
    if object.is_a?(Hash)
      schema.merge!(
        type: 'object',
        properties: dig_into_hash(object),
        required: object.keys
      )
    elsif object.is_a?(Array)
      schema.merge!(
        type: 'array',
        items: dig_into_array(object)
      )
    else
      schema.merge!(type: value_type(object))
    end
    schema
  end

  def self.dig_into_hash(hash)
    properties = {}
    hash.each_pair do |key, value|
      properties[key] = if value.is_a?(Hash)
        {
          type: 'object',
          required: value.keys,
          properties: dig_into_hash(value)
        }
      elsif value.is_a?(Array)
        {
          type: 'array',
          items: dig_into_array(value)
        }
      else
        {
          type: value_type(value)
        }
      end
    end
    properties
  end

  def self.dig_into_array(array)
    return {} if array.empty?
    # Only care about first item
    object = array.first

    if object.is_a?(Hash)
      {
        type: 'object',
        properties: dig_into_hash(object),
        required: object.keys
      }
    elsif object.is_a?(Array)
      {
        type: 'array',
        items: dig_into_array(object)
      }
    else
      { type: value_type(object) }
    end
  end

  def self.value_type(value)
    case value
    when Hash
      'object'
    when Array
      'array'
    when true, false
      'boolean'
    when String
      'string'
    when Fixnum, Float
      'number'
    else
      'null'
    end
  end
end
