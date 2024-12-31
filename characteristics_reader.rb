require 'yaml'

class CharacteristicsReader
  def self.read(lines)
    data = { 'school_details' => YAML.load_file('template.yml')['school_details'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "School Category"
        data['school_details']['category'] = next_line if next_line && !next_line.match?(/Management/)
      when "School Type"
        data['school_details']['type'] = next_line if next_line && !next_line.match?(/Lowest/)
      when "Lowest & Highest Class"
        data['school_details']['class_range'] = next_line if next_line && !next_line.match?(/Pre Primary/)
      when "Pre Primary"
        data['school_details']['pre_primary'] = next_line if next_line && !next_line.match?(/Medium/)
      when "Is Special School for CWSN?"
        data['school_details']['is_special_school'] = next_line if next_line && !next_line.match?(/Availability/)
      end
    end

    # Clean up empty sections
    data['school_details'].reject! { |_, v| v.nil? }

    data unless data['school_details'].empty?
  end
end 