class RteYamlWriter
  def self.format_yaml(data)
    return unless data

    {
      'rte' => data[:rte_numbers],
      'grades' => data[:grade_rows],
      'bg_pairs' => data[:bg_pairs]
    }
  end
end