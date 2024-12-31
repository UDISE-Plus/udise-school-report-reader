class AnganwadiDataReader
  def self.read(lines)
    data = { 'facilities' => { 'anganwadi' => YAML.load_file('template.yml')['facilities']['anganwadi'] } }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Anganwadi At Premises"
        data['facilities']['anganwadi']['at_premises'] = next_line if next_line
      when "Anganwadi Boys"
        data['facilities']['anganwadi']['boys'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Girls"
        data['facilities']['anganwadi']['girls'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Worker"
        data['facilities']['anganwadi']['worker'] = next_line if next_line
      end
    end

    # Clean up empty sections
    data['facilities']['anganwadi'].reject! { |_, v| v.nil? }
    data['facilities'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data unless data['facilities']['anganwadi'].empty?
  end
end 