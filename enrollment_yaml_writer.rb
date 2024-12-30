class EnrollmentYamlWriter
  def self.format_yaml(data)
    return unless data

    grade_rows = data[:grade_rows]
    bg_pairs = data[:bg_pairs]

    categories = {
      'gen' => data[:gen_numbers],
      'sc' => data[:sc_numbers],
      'st' => data[:st_numbers],
      'obc' => data[:obc_numbers],
      'muslim' => data[:musl_numbers],
      'christian' => data[:chris_numbers],
      'sikh' => data[:sikh_numbers],
      'buddhist' => data[:budd_numbers],
      'parsi' => data[:parsi_numbers],
      'jain' => data[:jain_numbers],
      'others' => data[:others_numbers],
      'aadhaar' => data[:aadh_numbers],
      'bpl' => data[:bpl_numbers],
      'repeater' => data[:rept_numbers],
      'cwsn' => data[:cwsn_numbers]
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

    # Handle age data
    (3..22).each do |age|
      age_numbers = data[:"age_#{age}_numbers"]
      yaml_data["age_#{age}"] = {}
      bg_pairs.each_with_index do |(x_mid, _), index|
        next unless grade_rows[index] && grade_rows[index]['text']
        grade_name = grade_rows[index]['text'].downcase.gsub(' ', '_')
        nums = age_numbers&.[](x_mid)
        boys_text = nums&.first&.[]('text')&.strip
        girls_text = nums&.last&.[]('text')&.strip
        yaml_data["age_#{age}"][grade_name] = {
          'boys' => boys_text.nil? || boys_text.empty? ? nil : boys_text.to_i,
          'girls' => girls_text.nil? || girls_text.empty? ? nil : girls_text.to_i
        }
      end
    end

    yaml_data
  end
end