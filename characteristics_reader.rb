require 'yaml'

class CharacteristicsReader
  def self.read(lines)
    data = { 'characteristics' => {} }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "School Category"
        data['characteristics']['category'] = next_line if next_line && !next_line.match?(/Management/)
      when "School Type"
        data['characteristics']['type'] = next_line if next_line && !next_line.match?(/Lowest/)
      when "Lowest & Highest Class"
        data['characteristics']['class_range'] = next_line if next_line && !next_line.match?(/Pre Primary/)
      when "Pre Primary"
        data['characteristics']['pre_primary'] = next_line if next_line && !next_line.match?(/Medium/)
      when "Is Special School for CWSN?"
        data['characteristics']['is_special_school'] = next_line if next_line && !next_line.match?(/Availability/)
      end
    end

    # Clean up empty sections
    data['characteristics'].reject! { |_, v| v.nil? }

    data unless data['characteristics'].empty?
  end
end 