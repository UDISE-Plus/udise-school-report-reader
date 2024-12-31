class AnganwadiDataReader
  def self.read(lines)
    data = { 'anganwadi' => YAML.load_file('template.yml')['anganwadi'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "Anganwadi At Premises"
        data['anganwadi']['at_premises'] = next_line if next_line
      when "Anganwadi Boys"
        data['anganwadi']['boys'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Girls"
        data['anganwadi']['girls'] = next_line.to_i if next_line =~ /^\d+$/
      when "Anganwadi Worker"
        data['anganwadi']['worker'] = next_line if next_line
      end
    end

    # Clean up empty sections
    data['anganwadi'].reject! { |_, v| v.nil? }

    data unless data['anganwadi'].empty?
  end
end 