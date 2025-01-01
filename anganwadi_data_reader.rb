class AnganwadiDataReader
  FIELD_MAPPINGS = {
    'Anganwadi At Premises' => {
      key_path: ['anganwadi', 'at_premises']
    },
    'Anganwadi Boys' => {
      key_path: ['anganwadi', 'boys'],
      value_type: :integer
    },
    'Anganwadi Girls' => {
      key_path: ['anganwadi', 'girls'],
      value_type: :integer
    },
    'Anganwadi Worker' => {
      key_path: ['anganwadi', 'worker']
    }
  }

  def self.read(lines)
    data = { 'anganwadi' => YAML.load_file('template.yml')['anganwadi'] }

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
    data['anganwadi'].reject! { |_, v| v.nil? }

    data unless data['anganwadi'].empty?
  end
end 