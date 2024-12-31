class EnrollmentDataReader
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
    gen_rows = []
    sc_rows = []
    st_rows = []
    obc_rows = []
    musl_rows = []
    chris_rows = []
    sikh_rows = []
    budd_rows = []
    parsi_rows = []
    jain_rows = []
    others_rows = []
    aadh_rows = []
    bpl_rows = []
    rept_rows = []
    cwsn_rows = []
    age_3_rows = []
    age_4_rows = []
    age_5_rows = []
    age_6_rows = []
    age_7_rows = []
    age_8_rows = []
    age_9_rows = []
    age_10_rows = []
    age_11_rows = []
    age_12_rows = []
    age_13_rows = []
    age_14_rows = []
    age_15_rows = []
    age_16_rows = []
    age_17_rows = []
    age_18_rows = []
    age_19_rows = []
    age_20_rows = []
    age_21_rows = []
    age_22_rows = []

    # First pass to collect y-coordinates for categories
    CSV.foreach(@csv_path, headers: true) do |row|
      if row['page'] == '2' && row['rect_x'].to_f == 27.0
        case row['text']
        when "Gen" then @category_y_coords['gen'] = row['rect_y'].to_f
        when "SC" then @category_y_coords['sc'] = row['rect_y'].to_f
        when "ST" then @category_y_coords['st'] = row['rect_y'].to_f
        when "OBC" then @category_y_coords['obc'] = row['rect_y'].to_f
        when "Musl" then @category_y_coords['musl'] = row['rect_y'].to_f
        when "Chris" then @category_y_coords['chris'] = row['rect_y'].to_f
        when "Sikh" then @category_y_coords['sikh'] = row['rect_y'].to_f
        when "Budd" then @category_y_coords['budd'] = row['rect_y'].to_f
        when "Parsi" then @category_y_coords['parsi'] = row['rect_y'].to_f
        when "Jain" then @category_y_coords['jain'] = row['rect_y'].to_f
        when "Others" then @category_y_coords['others'] = row['rect_y'].to_f
        when "Aadh" then @category_y_coords['aadh'] = row['rect_y'].to_f
        when "BPL" then @category_y_coords['bpl'] = row['rect_y'].to_f
        when "Rept" then @category_y_coords['rept'] = row['rect_y'].to_f
        when "CWSN" then @category_y_coords['cwsn'] = row['rect_y'].to_f
        when ">3" then @category_y_coords['age_3'] = row['rect_y'].to_f
        when "4" then @category_y_coords['age_4'] = row['rect_y'].to_f
        when "5" then @category_y_coords['age_5'] = row['rect_y'].to_f
        when "6" then @category_y_coords['age_6'] = row['rect_y'].to_f
        when "7" then @category_y_coords['age_7'] = row['rect_y'].to_f
        when "8" then @category_y_coords['age_8'] = row['rect_y'].to_f
        when "9" then @category_y_coords['age_9'] = row['rect_y'].to_f
        when "10" then @category_y_coords['age_10'] = row['rect_y'].to_f
        when "11" then @category_y_coords['age_11'] = row['rect_y'].to_f
        when "12" then @category_y_coords['age_12'] = row['rect_y'].to_f
        when "13" then @category_y_coords['age_13'] = row['rect_y'].to_f
        when "14" then @category_y_coords['age_14'] = row['rect_y'].to_f
        when "15" then @category_y_coords['age_15'] = row['rect_y'].to_f
        when "16" then @category_y_coords['age_16'] = row['rect_y'].to_f
        when "17" then @category_y_coords['age_17'] = row['rect_y'].to_f
        when "18" then @category_y_coords['age_18'] = row['rect_y'].to_f
        when "19" then @category_y_coords['age_19'] = row['rect_y'].to_f
        when "20" then @category_y_coords['age_20'] = row['rect_y'].to_f
        when "21" then @category_y_coords['age_21'] = row['rect_y'].to_f
        when "22" then @category_y_coords['age_22'] = row['rect_y'].to_f
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
          case y_coord
          when @category_y_coords['gen'] then gen_rows << row
          when @category_y_coords['sc'] then sc_rows << row
          when @category_y_coords['st'] then st_rows << row
          when @category_y_coords['obc'] then obc_rows << row
          when @category_y_coords['musl'] then musl_rows << row
          when @category_y_coords['chris'] then chris_rows << row
          when @category_y_coords['sikh'] then sikh_rows << row
          when @category_y_coords['budd'] then budd_rows << row
          when @category_y_coords['parsi'] then parsi_rows << row
          when @category_y_coords['jain'] then jain_rows << row
          when @category_y_coords['others'] then others_rows << row
          when @category_y_coords['aadh'] then aadh_rows << row
          when @category_y_coords['bpl'] then bpl_rows << row
          when @category_y_coords['rept'] then rept_rows << row
          when @category_y_coords['cwsn'] then cwsn_rows << row
          when @category_y_coords['age_3'] then age_3_rows << row
          when @category_y_coords['age_4'] then age_4_rows << row
          when @category_y_coords['age_5'] then age_5_rows << row
          when @category_y_coords['age_6'] then age_6_rows << row
          when @category_y_coords['age_7'] then age_7_rows << row
          when @category_y_coords['age_8'] then age_8_rows << row
          when @category_y_coords['age_9'] then age_9_rows << row
          when @category_y_coords['age_10'] then age_10_rows << row
          when @category_y_coords['age_11'] then age_11_rows << row
          when @category_y_coords['age_12'] then age_12_rows << row
          when @category_y_coords['age_13'] then age_13_rows << row
          when @category_y_coords['age_14'] then age_14_rows << row
          when @category_y_coords['age_15'] then age_15_rows << row
          when @category_y_coords['age_16'] then age_16_rows << row
          when @category_y_coords['age_17'] then age_17_rows << row
          when @category_y_coords['age_18'] then age_18_rows << row
          when @category_y_coords['age_19'] then age_19_rows << row
          when @category_y_coords['age_20'] then age_20_rows << row
          when @category_y_coords['age_21'] then age_21_rows << row
          when @category_y_coords['age_22'] then age_22_rows << row
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

    all_data_rows = [
      gen_rows, sc_rows, st_rows, obc_rows, musl_rows, chris_rows, sikh_rows, budd_rows,
      parsi_rows, jain_rows, others_rows, aadh_rows, bpl_rows, age_3_rows, age_4_rows, age_5_rows,
      age_6_rows, age_7_rows, age_8_rows, age_9_rows, age_10_rows, age_11_rows, age_12_rows,
      age_13_rows, age_14_rows, age_15_rows, age_16_rows, age_17_rows, age_18_rows, age_19_rows,
      age_20_rows, age_21_rows, age_22_rows
    ]

    all_data_rows.each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
      rows.reject! { |row| row['text_x'].to_f >= @x_cutoff }
    end

    # Group B,G pairs
    bg_pairs = bg_rows.each_slice(2).map do |b, g|
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      [x_mid, [b, g]]
    end.to_h

    # Match numbers to pairs
    {
      grade_rows: grade_rows,
      bg_pairs: bg_pairs,
      gen_numbers: match_numbers_to_pairs(gen_rows, bg_pairs),
      sc_numbers: match_numbers_to_pairs(sc_rows, bg_pairs),
      st_numbers: match_numbers_to_pairs(st_rows, bg_pairs),
      obc_numbers: match_numbers_to_pairs(obc_rows, bg_pairs),
      musl_numbers: match_numbers_to_pairs(musl_rows, bg_pairs),
      chris_numbers: match_numbers_to_pairs(chris_rows, bg_pairs),
      sikh_numbers: match_numbers_to_pairs(sikh_rows, bg_pairs),
      budd_numbers: match_numbers_to_pairs(budd_rows, bg_pairs),
      parsi_numbers: match_numbers_to_pairs(parsi_rows, bg_pairs),
      jain_numbers: match_numbers_to_pairs(jain_rows, bg_pairs),
      others_numbers: match_numbers_to_pairs(others_rows, bg_pairs),
      aadh_numbers: match_numbers_to_pairs(aadh_rows, bg_pairs),
      bpl_numbers: match_numbers_to_pairs(bpl_rows, bg_pairs),
      rept_numbers: match_numbers_to_pairs(rept_rows, bg_pairs),
      cwsn_numbers: match_numbers_to_pairs(cwsn_rows, bg_pairs),
      age_3_numbers: match_numbers_to_pairs(age_3_rows, bg_pairs),
      age_4_numbers: match_numbers_to_pairs(age_4_rows, bg_pairs),
      age_5_numbers: match_numbers_to_pairs(age_5_rows, bg_pairs),
      age_6_numbers: match_numbers_to_pairs(age_6_rows, bg_pairs),
      age_7_numbers: match_numbers_to_pairs(age_7_rows, bg_pairs),
      age_8_numbers: match_numbers_to_pairs(age_8_rows, bg_pairs),
      age_9_numbers: match_numbers_to_pairs(age_9_rows, bg_pairs),
      age_10_numbers: match_numbers_to_pairs(age_10_rows, bg_pairs),
      age_11_numbers: match_numbers_to_pairs(age_11_rows, bg_pairs),
      age_12_numbers: match_numbers_to_pairs(age_12_rows, bg_pairs),
      age_13_numbers: match_numbers_to_pairs(age_13_rows, bg_pairs),
      age_14_numbers: match_numbers_to_pairs(age_14_rows, bg_pairs),
      age_15_numbers: match_numbers_to_pairs(age_15_rows, bg_pairs),
      age_16_numbers: match_numbers_to_pairs(age_16_rows, bg_pairs),
      age_17_numbers: match_numbers_to_pairs(age_17_rows, bg_pairs),
      age_18_numbers: match_numbers_to_pairs(age_18_rows, bg_pairs),
      age_19_numbers: match_numbers_to_pairs(age_19_rows, bg_pairs),
      age_20_numbers: match_numbers_to_pairs(age_20_rows, bg_pairs),
      age_21_numbers: match_numbers_to_pairs(age_21_rows, bg_pairs),
      age_22_numbers: match_numbers_to_pairs(age_22_rows, bg_pairs)
    }
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
