class RteYamlWriter
  GRADE_MAPPING = {
    'Pre-Pri.' => 'pre-pri.',
    'Class I' => 'class_i',
    'Class II' => 'class_ii', 
    'Class III' => 'class_iii',
    'Class IV' => 'class_iv',
    'Class V' => 'class_v',
    'Class VI' => 'class_vi',
    'Class VII' => 'class_vii',
    'Class VIII' => 'class_viii',
    'Class IX' => 'class_ix',
    'Class X' => 'class_x',
    'Class XI' => 'class_xi',
    'Class XII' => 'class_xii'
  }

  def self.format_yaml(data)
    return unless data

    rte_data = { 'rte' => {} }
    
    # Get grade names and their indices
    grades = data[:grade_rows].map { |row| row['text'] }
    grade_indices = {}
    grades.each_with_index do |grade, idx|
      grade_indices[idx] = GRADE_MAPPING[grade] || grade.downcase.gsub(/\s+/, '_')
    end

    # Initialize structure for each grade
    grade_indices.values.each do |grade_key|
      rte_data['rte'][grade_key] = {
        'boys' => 0,
        'girls' => 0
      }
    end

    # Fill in values
    data[:rte_numbers].each do |x_mid, pair|
      next unless pair && pair.size == 2
      
      # Find corresponding grade index based on x position
      grade_idx = grade_indices.keys.find do |idx|
        x_start = data[:grade_rows][idx]['rect_x'].to_f
        x_end = x_start + data[:grade_rows][idx]['rect_width'].to_f
        x_mid >= x_start && x_mid <= x_end
      end
      
      next unless grade_idx && grade_indices[grade_idx]
      
      grade_key = grade_indices[grade_idx]
      boys_val = pair[0]&.dig('text')
      girls_val = pair[1]&.dig('text')
      
      rte_data['rte'][grade_key]['boys'] = boys_val == '-' ? 0 : boys_val.to_i
      rte_data['rte'][grade_key]['girls'] = girls_val == '-' ? 0 : girls_val.to_i
    end

    rte_data
  end
end