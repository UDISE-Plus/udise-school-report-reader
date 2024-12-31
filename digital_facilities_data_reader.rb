class DigitalFacilitiesDataReader
  def self.read(lines)
    data = { 'infrastructure' => { 'digital_facilities' => YAML.load_file('template.yml')['infrastructure']['digital_facilities'] } }

    lines.each_with_index do |line, i|
      case line
      when /Digital/
        data['infrastructure']['digital_facilities']['ict_lab'] = lines[i + 2] if lines[i + 2] =~ /^[12]-/
        data['infrastructure']['digital_facilities']['internet'] = lines[i + 4] if lines[i + 4] =~ /^[12]-/
        if lines[i + 6] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['desktop'] = lines[i + 6].to_i
        end
        if lines[i + 8] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['laptop'] = lines[i + 8].to_i
        end
        if lines[i + 10] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['computers']['tablet'] = lines[i + 10].to_i
        end
        if lines[i + 12] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['peripherals']['printer'] = lines[i + 12].to_i
        end
        if lines[i + 14] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['peripherals']['projector'] = lines[i + 14].to_i
        end
        data['infrastructure']['digital_facilities']['smart_classroom']['dth'] = lines[i + 16] if lines[i + 16] =~ /^[12]-/
        if lines[i + 18] =~ /^\d+$/
          data['infrastructure']['digital_facilities']['smart_classroom']['digiboard'] = lines[i + 18].to_i
        end
      end
    end

    # Clean up empty sections
    data['infrastructure']['digital_facilities'].each do |key, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data['infrastructure']['digital_facilities'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data unless data['infrastructure']['digital_facilities'].empty?
  end
end 