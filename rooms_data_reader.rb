class RoomsDataReader
  FIELD_MAPPINGS = {
    'In Good Condition' => {
      key_path: ['rooms', 'classrooms', 'good_condition'],
      value_type: :integer,
      end_pattern: /Needs Minor/
    },
    'Needs Minor Repair' => {
      key_path: ['rooms', 'classrooms', 'needs_minor_repair'],
      value_type: :integer,
      end_pattern: /Needs Major/
    },
    'Needs Major Repair' => {
      key_path: ['rooms', 'classrooms', 'needs_major_repair'],
      value_type: :integer,
      end_pattern: /Other Rooms/
    },
    'Other Rooms' => {
      key_path: ['rooms', 'other'],
      value_type: :integer,
      end_pattern: /Library/
    },
    'Library Availability' => {
      key_path: ['rooms', 'library'],
      end_pattern: /Solar/
    },
    'Separate Room for HM' => {
      key_path: ['rooms', 'hm'],
      end_pattern: /Drinking/
    }
  }

  def self.read(lines)
    require 'yaml'
    template = YAML.load_file('template.yml')
    data = { 'rooms' => template['rooms'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip
      
      if mapping = FIELD_MAPPINGS[line]
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

    # Clean up empty sections
    data['rooms'].each do |key, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data['rooms'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data
  end
end 