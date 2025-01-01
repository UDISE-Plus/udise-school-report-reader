class ActivitiesDataReader
  def self.read(lines)
    data = {
      'activities' => {
        'inspections' => {},
        'instructional_days' => {},
        'student_hours' => {},
        'teacher_hours' => {}
      }
    }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Acad. Inspections"
        data['activities']['inspections']['academic'] = next_line.to_i if next_line =~ /^\d+$/
      when "CRC Coordinator"
        data['activities']['inspections']['crc_coordinator'] = next_line.to_i if next_line =~ /^\d+$/
      when "Block Level Officers"
        data['activities']['inspections']['block_level'] = next_line.to_i if next_line =~ /^\d+$/
      when "State/District Officers"
        data['activities']['inspections']['state_district'] = next_line.to_i if next_line =~ /^\d+$/
      when "Instructional days"
        if lines[i + 1] =~ /^\d+$/
          data['activities']['instructional_days']['primary'] = lines[i + 1].to_i
          data['activities']['instructional_days']['upper_primary'] = lines[i + 2].to_i if lines[i + 2] =~ /^\d+$/
          data['activities']['instructional_days']['secondary'] = lines[i + 3].to_i if lines[i + 3] =~ /^\d+$/
          data['activities']['instructional_days']['higher_secondary'] = lines[i + 4].to_i if lines[i + 4] =~ /^\d+$/
        end
      when "Avg.School hrs.Std."
        if lines[i + 1] =~ /^\d+\.?\d*$/
          data['activities']['student_hours']['primary'] = lines[i + 1].to_f
          data['activities']['student_hours']['upper_primary'] = lines[i + 2].to_f if lines[i + 2] =~ /^\d+\.?\d*$/
          data['activities']['student_hours']['secondary'] = lines[i + 3].to_f if lines[i + 3] =~ /^\d+\.?\d*$/
          data['activities']['student_hours']['higher_secondary'] = lines[i + 4].to_f if lines[i + 4] =~ /^\d+\.?\d*$/
        end
      when "Avg.School hrs.Tch."
        if lines[i + 1] =~ /^\d+\.?\d*$/
          data['activities']['teacher_hours']['primary'] = lines[i + 1].to_f
          data['activities']['teacher_hours']['upper_primary'] = lines[i + 2].to_f if lines[i + 2] =~ /^\d+\.?\d*$/
          data['activities']['teacher_hours']['secondary'] = lines[i + 3].to_f if lines[i + 3] =~ /^\d+\.?\d*$/
          data['activities']['teacher_hours']['higher_secondary'] = lines[i + 4].to_f if lines[i + 4] =~ /^\d+\.?\d*$/
        end
      end
    end

    # Clean up empty sections
    data['activities']['inspections'].reject! { |_, v| v.nil? }
    data['activities']['instructional_days'].reject! { |_, v| v.nil? }
    data['activities']['student_hours'].reject! { |_, v| v.nil? }
    data['activities']['teacher_hours'].reject! { |_, v| v.nil? }
    data['activities'].reject! { |_, v| v.empty? }
    data.reject! { |_, v| v.empty? }

    data
  end
end 