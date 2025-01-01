class EwsYamlWriter
  def self.format_yaml(data)
    return unless data

    grade_rows = data[:grade_rows]
    bg_pairs = data[:bg_pairs]

    categories = {
      'ews' => data[:ews_numbers],
    }

    yaml_data = {}

    categories.each do |category, numbers|
      yaml_data[category] = {}
      bg_pairs.each_with_index do |(x_mid, _), index|
        next unless grade_rows[index] && grade_rows[index]['text']
        grade_name = grade_rows[index]['text'].downcase.gsub(' ', '_')
        nums = numbers&.[](x_mid)
        boys_text = nums&.first&.[]('text')&.strip
        girls_text = nums&.last&.[]('text')&.strip
        yaml_data[category][grade_name] = {
          'boys' => boys_text.nil? || boys_text.empty? ? nil : boys_text.to_i,
          'girls' => girls_text.nil? || girls_text.empty? ? nil : girls_text.to_i
        }
      end
    end

    yaml_data
  end
end