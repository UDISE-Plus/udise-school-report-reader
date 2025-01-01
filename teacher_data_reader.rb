require_relative 'data_reader_base'

class TeacherDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'Regular' => {
      key_path: ['teachers', 'count_by_level', 'regular'],
      value_type: :integer
    },
    'Part-time' => {
      key_path: ['teachers', 'count_by_level', 'part_time'],
      value_type: :integer
    },
    'Contract' => {
      key_path: ['teachers', 'count_by_level', 'contract'],
      value_type: :integer
    },
    'Male' => {
      key_path: ['teachers', 'demographics', 'male'],
      value_type: :integer
    },
    'Female' => {
      key_path: ['teachers', 'demographics', 'female'],
      value_type: :integer
    },
    'Transgender' => {
      key_path: ['teachers', 'demographics', 'transgender'],
      value_type: :integer
    },
    'Below Graduate' => {
      key_path: ['teachers', 'qualifications', 'academic', 'below_graduate'],
      value_type: :integer
    },
    'Graduate' => {
      key_path: ['teachers', 'qualifications', 'academic', 'graduate'],
      value_type: :integer
    },
    'Post Graduate and Above' => {
      key_path: ['teachers', 'qualifications', 'academic', 'post_graduate_and_above'],
      value_type: :integer
    },
    'B.Ed. or Equivalent' => {
      key_path: ['teachers', 'qualifications', 'professional', 'bed'],
      value_type: :integer
    },
    'M.Ed. or Equivalent' => {
      key_path: ['teachers', 'qualifications', 'professional', 'med'],
      value_type: :integer
    },
    'Diploma or Certificate in basic teachers training' => {
      key_path: ['teachers', 'qualifications', 'professional', 'basic_training'],
      value_type: :integer
    },
    'Bachelor of Elementary Education (B.El.Ed.)' => {
      key_path: ['teachers', 'qualifications', 'professional', 'beled'],
      value_type: :integer
    },
    'Diploma/degree in special Education' => {
      key_path: ['teachers', 'qualifications', 'professional', 'special_education'],
      value_type: :integer
    },
    'Teachers Aged above 55' => {
      key_path: ['teachers', 'age_distribution', 'above_55'],
      value_type: :integer
    }
  }

  def self.read(lines)
    require 'yaml'
    template = YAML.load_file('template.yml')
    data = { 'teachers' => template['teachers'] }

    # Process base module mappings first
    base_data = super
    if base_data&.dig('teachers')
      data['teachers']['count_by_level'] = base_data['teachers']['count_by_level'] if base_data['teachers']['count_by_level']
      data['teachers']['demographics'] = base_data['teachers']['demographics'] if base_data['teachers']['demographics']
      data['teachers']['age_distribution'] = base_data['teachers']['age_distribution'] if base_data['teachers']['age_distribution']
      
      # Handle nested qualifications structure
      if base_data['teachers']['qualifications']
        data['teachers']['qualifications'] ||= {}
        data['teachers']['qualifications']['academic'] = base_data['teachers']['qualifications']['academic'] if base_data['teachers']['qualifications']['academic']
        data['teachers']['qualifications']['professional'] = base_data['teachers']['qualifications']['professional'] if base_data['teachers']['qualifications']['professional']
      end
    end

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
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

      when "Total Teacher Trained in Computer"
        if next_line =~ /^\d+$/
          data['teachers']['training']['computer_trained'] = next_line.to_i
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
      when "Other"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['other'] = next_line.to_i
        end
      when "None"
        if next_line =~ /^\d+$/
          data['teachers']['qualifications']['professional']['none'] = next_line.to_i
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