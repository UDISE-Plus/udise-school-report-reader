class OfficialDataReader
  def self.read(lines)
    require 'yaml'
    data = { 'official' => YAML.load_file('template.yml')['official'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Year of Establishment"
        data['official']['established'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Pri."
        data['official']['recognition']['primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Upr.Pri."
        data['official']['recognition']['upper_primary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Sec."
        data['official']['recognition']['secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Year of Recognition-Higher Sec."
        data['official']['recognition']['higher_secondary'] = next_line.to_i if next_line =~ /^\d+$/
      when "Affiliation Board-Sec"
        data['official']['affiliation']['secondary'] = next_line if next_line && !next_line.match?(/Affiliation Board-HSec/)
      when "Affiliation Board-HSec"
        data['official']['affiliation']['higher_secondary'] = next_line if next_line && !next_line.match?(/Is this/)
      when "School Management"
        data['official']['management'] = next_line if next_line && !next_line.match?(/School Type/)
      end
    end

    # Clean up empty sections
    data['official'].each do |key, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data['official'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data
  end
end 