class BuildingDataReader
  def self.read(lines)
    data = { 'building' => YAML.load_file('template.yml')['building'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Building Status"
        data['building']['status'] = next_line if next_line && !next_line.match?(/Boundary/)
      when "Boundary wall"
        data['building']['boundary_wall'] = next_line if next_line && !next_line.match?(/No\.of/)
      when "No.of Building Blocks"
        data['building']['blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Pucca Building Blocks"
        data['building']['pucca_blocks'] = next_line.to_i if next_line =~ /^\d+$/
      when "Is this a Shift School?"
        data['building']['has_shifts'] = next_line if next_line && !next_line.match?(/Building/)
      when "Availability of Ramps"
        data['building']['accessibility'] ||= {}
        data['building']['accessibility']['ramps'] = next_line if next_line && !next_line.match?(/Availability of Hand/)
      when "Availability of Handrails"
        data['building']['accessibility'] ||= {}
        data['building']['accessibility']['handrails'] = next_line if next_line && !next_line.match?(/Anganwadi/)
      end
    end

    # Clean up empty sections
    data['building'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data unless data['building'].empty?
  end
end 