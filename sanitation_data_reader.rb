class SanitationDataReader
  FIELD_MAPPINGS = {
    'Handwash Near Toilet' => {
      key_path: ['sanitation', 'handwash', 'near_toilet'],
      end_pattern: /Handwash Facility/
    },
    'Handwash Facility for Meal' => {
      key_path: ['sanitation', 'handwash', 'for_meal'],
      end_pattern: /Total Class/
    },
    'Toilets' => {
      key_path: ['sanitation', 'toilets'],
      is_table: true,
      table_config: {
        sections: [
          {
            trigger: /Total.*CWSN/,
            offset: 1,
            fields: [
              { key: ['boys', 'total'], value_type: :integer },
              { key: ['girls', 'total'], value_type: :integer }
            ]
          },
          {
            trigger: "Functional",
            offset: 1,
            fields: [
              { key: ['boys', 'functional'], value_type: :integer },
              { key: ['girls', 'functional'], value_type: :integer }
            ]
          },
          {
            trigger: /CWSN Friendly/,
            offset: 1,
            fields: [
              { key: ['boys', 'cwsn'], value_type: :integer },
              { key: ['girls', 'cwsn'], value_type: :integer }
            ]
          },
          {
            trigger: "Urinal",
            offset: 1,
            fields: [
              { key: ['boys', 'urinals'], value_type: :integer },
              { key: ['girls', 'urinals'], value_type: :integer }
            ]
          }
        ]
      }
    }
  }

  def self.read(lines)
    require 'yaml'
    template = YAML.load_file('template.yml')
    data = { 'sanitation' => template['infrastructure']['sanitation'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip
      
      if mapping = FIELD_MAPPINGS[line]
        if mapping[:is_table]
          # Handle table-like data (toilets)
          table_data = lines[i+1..i+20] # Look ahead for data
          mapping[:table_config][:sections].each do |section|
            idx = table_data.index { |l| l.match?(section[:trigger]) }
            if idx && idx + section[:offset] + section[:fields].length <= table_data.length
              section[:fields].each_with_index do |field, field_idx|
                value = table_data[idx + section[:offset] + field_idx]
                if value =~ /^\d+$/
                  # Ensure path exists and set value
                  current = data
                  full_path = mapping[:key_path] + field[:key]
                  full_path[0..-2].each do |key|
                    current[key] ||= {}
                    current = current[key]
                  end
                  current[full_path.last] = value.to_i
                end
              end
            end
          end
        else
          # Handle simple key-value data
          next unless next_line
          next if mapping[:end_pattern] && next_line.match?(mapping[:end_pattern])

          # Transform value based on type
          value = case mapping[:value_type]
          when :integer
            next_line.to_i if next_line =~ /^\d+$/
          else
            next_line
          end

          # Always ensure path exists and set the value
          current = data
          mapping[:key_path][0..-2].each do |key|
            current[key] ||= {}
            current = current[key]
          end
          current[mapping[:key_path].last] = value
        end
      end
    end

    # Clean up empty sections
    data['sanitation'].each do |key, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data['sanitation'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data
  end
end 