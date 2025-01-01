module DataReaderBase
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def read(lines)
      require 'yaml'
      template_path = File.join(UdiseSchoolReportReader::ROOT_PATH, 'template.yml')
      template = YAML.load_file(template_path)
      data = { base_key => template[base_key] }

      lines.each_with_index do |line, i|
        next_line = lines[i + 1]&.strip
        
        if mapping = self::FIELD_MAPPINGS[line]
          if mapping[:is_table]
            process_table_data(data, lines[i+1..i+20], mapping)
          else
            process_simple_field(data, next_line, mapping)
          end
        end
      end

      cleanup_data(data)
      data
    end

    private

    def process_table_data(data, table_lines, mapping)
      mapping[:table_config][:sections].each do |section|
        idx = table_lines.index { |l| l.match?(section[:trigger]) }
        if idx && idx + section[:offset] + section[:fields].length <= table_lines.length
          section[:fields].each_with_index do |field, field_idx|
            value = table_lines[idx + section[:offset] + field_idx]
            if value =~ /^\d+$/
              set_value_at_path(data, mapping[:key_path] + field[:key], transform_value(value, field[:value_type]))
            end
          end
        end
      end
    end

    def process_simple_field(data, next_line, mapping)
      return unless next_line
      return if mapping[:end_pattern] && next_line.match?(mapping[:end_pattern])

      value = transform_value(next_line, mapping[:value_type])
      set_value_at_path(data, mapping[:key_path], value)
    end

    def transform_value(value, type)
      case type
      when :integer
        value.to_i if value =~ /^\d+$/
      else
        value
      end
    end

    def set_value_at_path(data, path, value)
      current = data
      path[0..-2].each do |key|
        current[key] ||= {}
        current = current[key]
      end
      current[path.last] = value
    end

    def cleanup_data(data)
      base = data[base_key]
      return unless base.is_a?(Hash)

      base.each do |_, section|
        if section.is_a?(Hash)
          section.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
        end
      end
      base.reject! { |_, v| v.nil? || (v.is_a?(Hash) && v.empty?) }
    end

    def base_key
      self.name.gsub('DataReader', '').downcase
    end
  end
end 