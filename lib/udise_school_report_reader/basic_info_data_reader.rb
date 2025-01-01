class BasicInfoDataReader
  def self.read(lines)
    require 'yaml'
    template_path = File.join(UdiseSchoolReportReader::ROOT_PATH, 'template.yml')
    template = YAML.load_file(template_path)
    data = { 'basic_info' => template['basic_info'] }

    lines.each_with_index do |line, i|
      next_line = lines[i + 1]&.strip

      case line
      when "UDISE CODE"
        if next_line && (match = next_line.match(/(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{2})\s*(\d{3})/))
          data['basic_info']['udise_code'] = match[1..5].join('')
        end
      when "School Name"
        if next_line && next_line.include?("CARMEL")
          data['basic_info']['name'] = next_line
        end
      when /Academic Year.*:\s*(\d{4}-\d{2})/
        data['basic_info']['academic_year'] = $1
      end
    end

    # Clean up empty sections
    data['basic_info'].reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }

    data
  end
end 