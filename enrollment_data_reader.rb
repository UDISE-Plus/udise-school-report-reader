class EnrollmentDataReader
  ALL_CATEGORIES = [
    SOCIAL_CATEGORIES = [
      { key: 'gen', label: 'Gen' },
      { key: 'sc', label: 'SC' },
      { key: 'st', label: 'ST' },
      { key: 'obc', label: 'OBC' }
    ].freeze,
    RELIGION_CATEGORIES = [
      { key: 'musl', label: 'Musl' },
      { key: 'chris', label: 'Chris' },
      { key: 'sikh', label: 'Sikh' },
      { key: 'budd', label: 'Budd' },
      { key: 'parsi', label: 'Parsi' },
      { key: 'jain', label: 'Jain' },
      { key: 'others', label: 'Others' }
    ].freeze,
    OTHER_CATEGORIES = [
      { key: 'aadh', label: 'Aadh' },
      { key: 'bpl', label: 'BPL' },
      { key: 'rept', label: 'Rept' },
      { key: 'cwsn', label: 'CWSN' }
    ].freeze,
    AGE_CATEGORIES = (3..22).map do |age|
      { key: "age_#{age}", label: age == 3 ? '>3' : age.to_s }
    end.freeze,
  ].flatten.freeze

  def self.read(csv_path) = new(csv_path).read

  def initialize(csv_path)
    @csv_path = csv_path
    @x_cutoff = 0
    @category_y_coords = {}
  end

  def read
    # Initialize arrays for different row types
    grade_rows = []
    bg_rows = []
    category_rows = {}
    
    ALL_CATEGORIES.each do |category|
      category_rows[category[:key]] = []
    end

    # First pass to collect y-coordinates for categories
    CSV.foreach(@csv_path, headers: true) do |row|
      if row['page'] == '2' && (row['rect_x'].to_f - 27.0).abs < 5.0
        ALL_CATEGORIES.each do |category|
          if row['text'].downcase == category[:label].downcase
            @category_y_coords[category[:key]] = row['rect_y'].to_f
          end
        end
      end
    end

    CSV.foreach(@csv_path, headers: true) do |row|
      if row['page'] == '2'
        if row['text'] == "Total" && row['rect_y'].to_f == 778.0
          @x_cutoff = row['rect_x'].to_f
        end

        if ['Pre-Pr', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'].include?(row['text'])
          if row['text_y'].to_f == 780.0
            grade_rows << row
          end
        elsif ['B', 'G'].include?(row['text'])
          if row['text_y'].to_f == 768.0
            bg_rows << row
          end
        elsif row['text'] =~ /^\d+$/
          y_coord = row['rect_y'].to_f
          ALL_CATEGORIES.each do |category|
            if @category_y_coords[category[:key]] && (y_coord - @category_y_coords[category[:key]]).abs < 5.0
              category_rows[category[:key]] << row
            end
          end
        end
      end
    end

    return nil if grade_rows.empty?

    # Sort and filter rows
    [grade_rows, bg_rows].each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
      rows.reject! { |row| row['text_x'].to_f >= @x_cutoff }
    end

    category_rows.values.each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
      rows.reject! { |row| row['text_x'].to_f >= @x_cutoff }
    end

    # Group B,G pairs
    bg_pairs = bg_rows.each_slice(2).map do |b, g|
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      [x_mid, [b, g]]
    end.to_h

    # Match numbers to pairs
    result = {
      grade_rows: grade_rows,
      bg_pairs: bg_pairs
    }

    ALL_CATEGORIES.each do |category|
      result["#{category[:key]}_numbers".to_sym] = match_numbers_to_pairs(category_rows[category[:key]], bg_pairs)
    end

    result
  end

  private
    def match_numbers_to_pairs(remaining_numbers, bg_pairs, threshold = 10.0)
      numbers = {}
      remaining = remaining_numbers.dup

      bg_pairs.each do |x_mid, bg_pair|
        b_x = bg_pair[0]['text_x'].to_f
        g_x = bg_pair[1]['text_x'].to_f
        
        # Find numbers closest to B and G positions
        b_num = remaining.find { |row| (row['text_x'].to_f - b_x).abs < threshold }
        remaining.delete(b_num) if b_num

        g_num = remaining.find { |row| (row['text_x'].to_f - g_x).abs < threshold }
        remaining.delete(g_num) if g_num
        
        numbers[x_mid] = [b_num, g_num]
      end

      numbers
    end
end
