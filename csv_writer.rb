require 'csv'

class CSVWriter
  def self.write_blocks(blocks, csv_path)
    CSV.open(csv_path, 'wb') do |csv|
      csv << ['page', 'x', 'y', 'text', 'font', 'font_size']
      blocks.each do |block|
        csv << [
          block[:page],
          block[:x],
          block[:y],
          block[:text],
          block[:font],
          block[:font_size]
        ]
      end
    end
  end

  def self.write_rectangles(rectangles, csv_path)
    CSV.open(csv_path, 'wb') do |csv|
      csv << ['page', 'x', 'y', 'width', 'height', 'stroke_color', 'fill_color', 'line_width']
      rectangles.each do |rect|
        csv << [
          rect[:page],
          rect[:x],
          rect[:y],
          rect[:width],
          rect[:height],
          rect[:stroke_color],
          rect[:fill_color],
          rect[:line_width]
        ]
      end
    end
  end

  def self.write_combined(combined_data, output_path)
    CSV.open(output_path, 'wb') do |csv|
      csv << [
        'page',
        'text',
        'text_x',
        'text_y',
        'font',
        'font_size',
        'rect_x',
        'rect_y',
        'rect_width',
        'rect_height',
        'stroke_color',
        'fill_color',
        'line_width'
      ]

      combined_data.each do |data|
        csv << [
          data[:page],
          data[:text],
          data[:text_x],
          data[:text_y],
          data[:font],
          data[:font_size],
          data[:rect_x],
          data[:rect_y],
          data[:rect_width],
          data[:rect_height],
          data[:stroke_color],
          data[:fill_color],
          data[:line_width]
        ]
      end
    end
  end
end 