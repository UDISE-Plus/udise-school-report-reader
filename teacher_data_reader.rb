class TeacherDataReader
  def self.read(lines)
    require 'yaml'
    template = YAML.load_file('template.yml')
    data = { 'teachers' => template['teachers'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Regular"
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['regular'] = next_line.to_i
        end
      when "Part-time"
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['part_time'] = next_line.to_i
        end
      when "Contract"
        if next_line =~ /^\d+$/
          data['teachers']['count_by_level']['contract'] = next_line.to_i
        end
      when "Male"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['male'] = next_line.to_i
        end
      when "Female"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['female'] = next_line.to_i
        end
      when "Transgender"
        if next_line =~ /^\d+$/
          data['teachers']['demographics']['transgender'] = next_line.to_i
        end
      
      # Teacher Assignments and Classes
      when "Total Teacher Involve in Non Teaching Assignment"
        if next_line =~ /^\d+$/
          data['teachers']['assignments']['non_teaching'] = next_line.to_i
        end
      when /^(\d+)-(.+)$/
        category = $2.strip
        if next_line =~ /^\d+$/
          key = case category
          when 'Primary'
            'primary'
          when 'Up.Pr.'
            'upper_primary'
          when 'Pr. & Up.Pr.'
            'primary_and_upper_primary'
          when 'Sec. only'
            'secondary_only'
          when 'H Sec only.'
            'higher_secondary_only'
          when 'Up pri and Sec.'
            'upper_primary_and_secondary'
          when 'Sec and H Sec'
            'secondary_and_higher_secondary'
          when 'Pre-Primary Only.'
            'pre_primary_only'
          when 'Pre- Pri & Pri'
            'pre_primary_and_primary'
          else
            category.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
          end

          data['teachers']['classes_taught'][key] = next_line.to_i
        end

      # Teacher Qualifications
      when "Below Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['below_graduate'] = next_line.to_i
        end
      when "Graduate"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['graduate'] = next_line.to_i
        end
      when "Post Graduate and Above"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['academic']['post_graduate_and_above'] = next_line.to_i
        end
      when "Diploma or Certificate in basic teachers training"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['basic_training'] = next_line.to_i
        end
      when "B.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['bed'] = next_line.to_i
        end
      when "M.Ed. or Equivalent"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['med'] = next_line.to_i
        end
      when "Total Teacher Trained in Computer"
        if next_line =~ /^\d+$/
          data['teachers']['training']['computer_trained'] = next_line.to_i
        end
      when "Teachers Aged above 55"
        if next_line =~ /^\d+$/
          data['teachers']['age_distribution']['above_55'] = next_line.to_i
        end
      when "No. of Total Teacher Received Service Training"
        if next_line =~ /^\d+$/
          data['teachers']['training']['service']['total'] = next_line.to_i
        end
      when "Special Training Received"
        if next_line
          data['teachers']['training']['special'] ||= {}
          data['teachers']['training']['special']['received'] = next_line
        end
      when /Teaching Hours per Week/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['teaching_hours']['per_week'] = $1.to_i
        end
      when /Non-Teaching Hours/
        if next_line =~ /(\d+)/
          data['teachers']['workload']['non_teaching_hours']['per_week'] = $1.to_i
        end
      when /^Subject:\s*(.+?)(?:\s*,\s*Teachers:\s*(\d+))?$/
        subject = $1.strip
        count = $2&.to_i || 0
        data['teachers']['workload']['by_subject'][subject.downcase] = count
      when "Bachelor of Elementary Education (B.El.Ed.)"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['beled'] = next_line.to_i
        end
      when "Other"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['other'] = next_line.to_i
        end
      when "None"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['none'] = next_line.to_i
        end
      when "Diploma/degree in special Education"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['special_education'] = next_line.to_i
        end
      when "Pursuing any Relevant Professional Course"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['pursuing_course'] = next_line.to_i
        end
      end
    end

    # Clean up empty sections
    data['teachers'].each do |key, section|
      if section.is_a?(Hash)
        # Don't clean up assignments section
        next if key == 'assignments'
        section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
      end
    end
    data['teachers'].reject! { |k, v| v.nil? || (v.is_a?(Hash) && v.empty? && k != 'assignments') }

    data
  end
end 