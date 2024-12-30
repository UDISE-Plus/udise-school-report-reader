class EnrollmentDataReader
  def self.match_numbers_to_pairs(remaining_numbers, bg_pairs, threshold = 10.0)
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

  def self.read_data(combined_data_csv_path)
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

    CSV.foreach(combined_data_csv_path, headers: true) do |row|
      if row['page'] == '2'
        if ['Pre-Pr', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'].include?(row['text'])
          if row['text_y'].to_f == 780.0
            grade_rows << row
          end
        elsif ['B', 'G'].include?(row['text'])
          if row['text_y'].to_f == 768.0
            bg_rows << row
          end
        elsif row['text'] =~ /^\d+$/
          y_coord = row['text_y'].to_f
          case y_coord
          when 757.0 then gen_rows << row
          when 745.5 then sc_rows << row
          when 734.0 then st_rows << row
          when 722.5, 718.25 then obc_rows << row
          when 669.5 then musl_rows << row
          when 658.0 then chris_rows << row
          when 646.5 then sikh_rows << row
          when 635.0 then budd_rows << row
          when 623.5 then parsi_rows << row
          when 612.0 then jain_rows << row
          when 600.5 then others_rows << row
          when 589.0 then aadh_rows << row
          when 566.5 then bpl_rows << row
          when 555.0 then rept_rows << row
          when 543.5 then cwsn_rows << row
          when 495.0 then age_3_rows << row
          when 483.5 then age_4_rows << row
          when 472.0 then age_5_rows << row
          when 460.5 then age_6_rows << row
          when 449.0 then age_7_rows << row
          when 437.5 then age_8_rows << row
          when 426.0 then age_9_rows << row
          when 414.5 then age_10_rows << row
          when 403.0 then age_11_rows << row
          when 391.5 then age_12_rows << row
          when 380.0 then age_13_rows << row
          when 368.5 then age_14_rows << row
          when 357.0 then age_15_rows << row
          when 345.5 then age_16_rows << row
          when 334.0 then age_17_rows << row
          when 322.5 then age_18_rows << row
          when 311.0 then age_19_rows << row
          when 299.5 then age_20_rows << row
          when 288.0 then age_21_rows << row
          when 276.5 then age_22_rows << row
          end
        end
      end
    end

    return nil if grade_rows.empty?

    # Sort and filter rows
    [grade_rows, bg_rows].each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
      rows.reject! { |row| row['text_x'].to_f >= 500 }
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
      rows.reject! { |row| row['text_x'].to_f >= 500 }
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
end 