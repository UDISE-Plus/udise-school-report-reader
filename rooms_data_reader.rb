class RoomsDataReader
  def self.read(lines)
    data = {
      'rooms' => {
        'classrooms' => {
          'good_condition' => 0,
          'needs_minor_repair' => 0,
          'needs_major_repair' => 0
        },
        'other' => 0,
        'library' => nil,
        'hm' => nil
      }
    }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "In Good Condition"
        if next_line =~ /^\d+$/
          data['rooms']['classrooms']['good_condition'] = next_line.to_i
        end
      when "Needs Minor Repair"
        if next_line =~ /^\d+$/
          data['rooms']['classrooms']['needs_minor_repair'] = next_line.to_i
        end
      when "Needs Major Repair"
        if next_line =~ /^\d+$/
          data['rooms']['classrooms']['needs_major_repair'] = next_line.to_i
        end
      when "Other Rooms"
        if next_line =~ /^\d+$/
          data['rooms']['other'] = next_line.to_i
        end
      when "Library Availability"
        data['rooms']['library'] = next_line if next_line && !next_line.match?(/Solar/)
      when "Separate Room for HM"
        data['rooms']['hm'] = next_line if next_line && !next_line.match?(/Drinking/)
      end
    end

    # Clean up empty sections
    data['rooms'].each do |_, section|
      if section.is_a?(Hash)
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data.reject! { |_, v| v.empty? }

    data
  end
end 