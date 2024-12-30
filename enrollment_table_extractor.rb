class EnrollmentTableExtractor
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

  def self.extract_table(combined_path, html_path)
    # Read the combined CSV file
    header_row = nil
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

    CSV.foreach(combined_path, headers: true) do |row|
      if row['text'] == 'Enrolment \(By Social Category\)' && row['page'] == '2'
        header_row = row
      elsif header_row && row['page'] == '2' && ['Pre-Pr', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'].include?(row['text'])
        # Only keep rows with y=780.0 (closest to header)
        if row['text_y'].to_f == 780.0
          grade_rows << row
        end
      elsif header_row && row['page'] == '2' && ['B', 'G'].include?(row['text'])
        # Get the B,G row at y=768.0
        if row['text_y'].to_f == 768.0
          bg_rows << row
        end
      elsif header_row && row['page'] == '2' && row['text'] =~ /^\d+$/
        # Get the Gen category numbers at y=757.0, SC at y=745.5, ST at y=734.0, OBC at y=722.5, Musl at y=669.5, Chris at y=658.0, Sikh at y=646.5, Buddhist at y=635.0, and Parsi at y=623.5
        y_coord = row['text_y'].to_f
        if y_coord == 757.0
          gen_rows << row
        elsif y_coord == 745.5
          sc_rows << row
        elsif y_coord == 734.0
          st_rows << row
        elsif y_coord == 722.5 || y_coord == 718.25
          obc_rows << row
        elsif y_coord == 669.5
          musl_rows << row
        elsif y_coord == 658.0
          chris_rows << row
        elsif y_coord == 646.5
          sikh_rows << row
        elsif y_coord == 635.0
          budd_rows << row
        elsif y_coord == 623.5
          parsi_rows << row
        elsif y_coord == 612.0
          jain_rows << row
        elsif y_coord == 600.5
          others_rows << row
        elsif y_coord == 589.0
          aadh_rows << row
        elsif y_coord == 566.5
          bpl_rows << row
        elsif y_coord == 555.0
          rept_rows << row
        elsif y_coord == 543.5
          cwsn_rows << row
        elsif y_coord == 495.0
          age_3_rows << row
        elsif y_coord == 483.5
          age_4_rows << row
        elsif y_coord == 472.0
          age_5_rows << row
        elsif y_coord == 460.5
          age_6_rows << row
        elsif y_coord == 449.0
          age_7_rows << row
        elsif y_coord == 437.5
          age_8_rows << row
        elsif y_coord == 426.0
          age_9_rows << row
        elsif y_coord == 414.5
          age_10_rows << row
        elsif y_coord == 403.0
          age_11_rows << row
        elsif y_coord == 391.5
          age_12_rows << row
        elsif y_coord == 380.0
          age_13_rows << row
        elsif y_coord == 368.5
          age_14_rows << row
        elsif y_coord == 357.0
          age_15_rows << row
        elsif y_coord == 345.5
          age_16_rows << row
        elsif y_coord == 334.0
          age_17_rows << row
        elsif y_coord == 322.5
          age_18_rows << row
        elsif y_coord == 311.0
          age_19_rows << row
        elsif y_coord == 299.5
          age_20_rows << row
        elsif y_coord == 288.0
          age_21_rows << row
        elsif y_coord == 276.5
          age_22_rows << row
        end
      end
    end

    return unless header_row

    # Sort rows by x coordinate to maintain order
    grade_rows.sort_by! { |row| row['text_x'].to_f }
    bg_rows.sort_by! { |row| row['text_x'].to_f }
    [gen_rows, sc_rows, st_rows, obc_rows, musl_rows, chris_rows, sikh_rows, budd_rows, 
     parsi_rows, jain_rows, others_rows, aadh_rows, bpl_rows, age_3_rows, age_4_rows, age_5_rows,
     age_6_rows, age_7_rows, age_8_rows, age_9_rows, age_10_rows, age_11_rows, age_12_rows,
     age_13_rows, age_14_rows, age_15_rows, age_16_rows, age_17_rows, age_18_rows, age_19_rows,
     age_20_rows, age_21_rows, age_22_rows].each do |rows|
      rows.sort_by! { |row| row['text_x'].to_f }
    end

    # Filter out total columns (those with x >= 500)
    grade_rows.reject! { |row| row['text_x'].to_f >= 500 }
    bg_rows.reject! { |row| row['text_x'].to_f >= 500 }
    [gen_rows, sc_rows, st_rows, obc_rows, musl_rows, chris_rows, sikh_rows, budd_rows,
     parsi_rows, jain_rows, others_rows, aadh_rows, bpl_rows, age_3_rows, age_4_rows, age_5_rows,
     age_6_rows, age_7_rows, age_8_rows, age_9_rows, age_10_rows, age_11_rows, age_12_rows,
     age_13_rows, age_14_rows, age_15_rows, age_16_rows, age_17_rows, age_18_rows, age_19_rows,
     age_20_rows, age_21_rows, age_22_rows].each do |rows|
      rows.reject! { |row| row['text_x'].to_f >= 500 }
    end

    # Group B,G pairs by their x-coordinates
    bg_pairs = bg_rows.each_slice(2).map do |b, g|
      x_mid = (b['text_x'].to_f + g['text_x'].to_f) / 2
      [x_mid, [b, g]]
    end.to_h

    # Match numbers to B,G pairs
    gen_numbers = match_numbers_to_pairs(gen_rows, bg_pairs)
    sc_numbers = match_numbers_to_pairs(sc_rows, bg_pairs)
    st_numbers = match_numbers_to_pairs(st_rows, bg_pairs)
    obc_numbers = match_numbers_to_pairs(obc_rows, bg_pairs)
    musl_numbers = match_numbers_to_pairs(musl_rows, bg_pairs)
    chris_numbers = match_numbers_to_pairs(chris_rows, bg_pairs)
    sikh_numbers = match_numbers_to_pairs(sikh_rows, bg_pairs)
    budd_numbers = match_numbers_to_pairs(budd_rows, bg_pairs)
    parsi_numbers = match_numbers_to_pairs(parsi_rows, bg_pairs)
    jain_numbers = match_numbers_to_pairs(jain_rows, bg_pairs)
    others_numbers = match_numbers_to_pairs(others_rows, bg_pairs)
    aadh_numbers = match_numbers_to_pairs(aadh_rows, bg_pairs)
    bpl_numbers = match_numbers_to_pairs(bpl_rows, bg_pairs)
    rept_numbers = match_numbers_to_pairs(rept_rows, bg_pairs)
    cwsn_numbers = match_numbers_to_pairs(cwsn_rows, bg_pairs)
    age_3_numbers = match_numbers_to_pairs(age_3_rows, bg_pairs)
    age_4_numbers = match_numbers_to_pairs(age_4_rows, bg_pairs)
    age_5_numbers = match_numbers_to_pairs(age_5_rows, bg_pairs)
    age_6_numbers = match_numbers_to_pairs(age_6_rows, bg_pairs)
    age_7_numbers = match_numbers_to_pairs(age_7_rows, bg_pairs)
    age_8_numbers = match_numbers_to_pairs(age_8_rows, bg_pairs)
    age_9_numbers = match_numbers_to_pairs(age_9_rows, bg_pairs)
    age_10_numbers = match_numbers_to_pairs(age_10_rows, bg_pairs)
    age_11_numbers = match_numbers_to_pairs(age_11_rows, bg_pairs)
    age_12_numbers = match_numbers_to_pairs(age_12_rows, bg_pairs)
    age_13_numbers = match_numbers_to_pairs(age_13_rows, bg_pairs)
    age_14_numbers = match_numbers_to_pairs(age_14_rows, bg_pairs)
    age_15_numbers = match_numbers_to_pairs(age_15_rows, bg_pairs)
    age_16_numbers = match_numbers_to_pairs(age_16_rows, bg_pairs)
    age_17_numbers = match_numbers_to_pairs(age_17_rows, bg_pairs)
    age_18_numbers = match_numbers_to_pairs(age_18_rows, bg_pairs)
    age_19_numbers = match_numbers_to_pairs(age_19_rows, bg_pairs)
    age_20_numbers = match_numbers_to_pairs(age_20_rows, bg_pairs)
    age_21_numbers = match_numbers_to_pairs(age_21_rows, bg_pairs)
    age_22_numbers = match_numbers_to_pairs(age_22_rows, bg_pairs)

    # Create HTML file with the header and grade information
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Enrollment Table</title>
        <style>
          table { border-collapse: collapse; margin-top: 20px; width: 100%; }
          th, td { border: 1px solid black; padding: 8px; text-align: center; }
          .header { font-weight: bold; background-color: #f0f0f0; }
          .grade { font-weight: bold; background-color: #e0e0e0; }
          .bg-pair { background-color: #f8f8f8; }
          .category { font-weight: bold; text-align: left; }
        </style>
      </head>
      <body>
        <h2>#{header_row['text']}</h2>
        <table>
          <tr class="grade">
            <th rowspan="2">Category</th>
            #{grade_rows.map { |row| "<th colspan='2'>#{row['text']}</th>" }.join}
          </tr>
          <tr class="bg-pair">
            #{grade_rows.map { |_| "<td>B</td><td>G</td>" }.join}
          </tr>
          <tr>
            <td class="category">Gen</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = gen_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">SC</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = sc_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">ST</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = st_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">OBC</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = obc_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Muslim</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = musl_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Christian</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = chris_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Sikh</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = sikh_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Buddhist</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = budd_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Parsi</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = parsi_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Jain</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = jain_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Others</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = others_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Aadhaar</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = aadh_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">BPL</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = bpl_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Repeater</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = rept_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">CWSN</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = cwsn_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 3</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_3_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 4</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_4_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 5</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_5_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 6</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_6_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 7</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_7_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 8</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_8_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 9</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_9_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 10</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_10_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 11</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_11_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 12</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_12_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 13</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_13_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 14</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_14_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 15</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_15_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 16</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_16_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 17</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_17_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 18</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_18_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 19</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_19_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 20</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_20_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 21</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_21_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
          <tr>
            <td class="category">Age 22</td>
            #{bg_pairs.map { |x_mid, _|
              numbers = age_22_numbers[x_mid]
              b_num = numbers&.first
              g_num = numbers&.last
              "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
            }.join}
          </tr>
        </table>
      </body>
      </html>
    HTML

    File.write(html_path, html_content)
  end
end 