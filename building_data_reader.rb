class BuildingDataReader
  def self.read(lines)
    data = { 'infrastructure' => { 'building' => { 'details' => YAML.load_file('template.yml')['infrastructure']['building']['details'] } } }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Building Status"
        data['infrastructure']['building']['details']['status'] = next_line if next_line && !next_line.match?(/Boundary/)
      when "Boundary wall"
        data['infrastructure']['building']['details']['boundary_wall'] = next_line if next_line && !next_line.match?(/No\.of/)
      when "No.of Building Blocks"
        data['infrastructure']['building']['details']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Pucca Building Blocks"
        data['infrastructure']['building']['details']['pucca_blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Is this a Shift School?"
        data['school_details'] ||= {}
        data['school_details']['shifts'] ||= {}
        data['school_details']['shifts']['has_shifts'] = next_line if next_line && !next_line.match?(/Building/)
      end
    end

    # Clean up empty sections
    data['infrastructure']['building']['details'].reject! { |_, v| v.nil? }
    data['infrastructure']['building'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
    data['infrastructure'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
    data['school_details']['shifts'].reject! { |_, v| v.nil? } if data['school_details'] && data['school_details']['shifts']
    data['school_details'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) } if data['school_details']
    data.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data unless data.empty?
  end
end 