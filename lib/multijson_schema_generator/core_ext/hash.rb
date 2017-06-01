class Hash
  def deep_extended_merge!(other_hash)
    other_hash.each_pair do |current_key, other_value|
      this_value = self[current_key]

      self[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
        this_value.deep_extended_merge(other_value)
      elsif this_value.is_a?(Array) && other_value.is_a?(Array)
        this_value + other_value
      else
        return this_value if other_value == 'null'
        other_value || this_value
      end
    end
    self
  end

  def deep_extended_merge(other_hash)
    dup.deep_extended_merge!(other_hash)
  end
end
