class BuildingDataReader
  FIELD_MAPPINGS = {
    'Building Status' => {
      key_path: ['building', 'status'],
      end_pattern: /Boundary/
    },
    'Boundary wall' => {
      key_path: ['building', 'boundary_wall'],
      end_pattern: /No\.of/
    },
    'No.of Building Blocks' => {
      key_path: ['building', 'blocks'],
      value_type: :integer
    },
    'Pucca Building Blocks' => {
      key_path: ['building', 'pucca_blocks'],
      value_type: :integer
    },
    'Is this a Shift School?' => {
      key_path: ['building', 'has_shifts'],
      end_pattern: /Building/
    },
    'Availability of Ramps' => {
      key_path: ['building', 'accessibility', 'ramps'],
      end_pattern: /Availability of Hand/
    },
    'Availability of Handrails' => {
      key_path: ['building', 'accessibility', 'handrails'],
      end_pattern: /Anganwadi/
    }
  }

  def self.read(lines)
    data = { 'building' => YAML.load_file('template.yml')['building'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip
      
      if mapping = FIELD_MAPPINGS[line]
        next unless next_line

        # Skip if next line matches end pattern
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

    # Clean up empty sections
    data['building'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data unless data['building'].empty?
  end
end 