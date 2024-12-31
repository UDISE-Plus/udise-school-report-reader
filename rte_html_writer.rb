class RteHtmlWriter
  def self.generate_html(data, html_path)
    return unless data

    grade_rows = data[:grade_rows]
    bg_pairs = data[:bg_pairs]

    categories = [
      ['EWS', data[:ews_numbers] || {}],
    ]

    # Generate table rows for all categories
    table_rows = categories.map do |category, numbers|
      cells = bg_pairs.map do |x_mid, _|
        nums = numbers[x_mid.to_s] || numbers[x_mid] || []
        b_num = nums&.first
        g_num = nums&.last
        "<td>#{b_num ? b_num['text'] : ''}</td><td>#{g_num ? g_num['text'] : ''}</td>"
      end.join

      "    <tr>\n" \
      "      <td class=\"category\">#{category}</td>\n" \
      "      #{cells}\n" \
      "    </tr>"
    end.join("\n")

    # Generate grade headers
    grade_headers = grade_rows.map { |row| "<th colspan='2'>#{row['text']}</th>" }.join
    bg_headers = grade_rows.map { |_| "<td>B</td><td>G</td>" }.join

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
        <h2>Enrolment (By Social Category)</h2>
        <table>
          <tr class="grade">
            <th rowspan="2">Category</th>
            #{grade_headers}
          </tr>
          <tr class="bg-pair">
            #{bg_headers}
          </tr>
      #{table_rows}
        </table>
      </body>
      </html>
    HTML

    File.write(html_path, html_content)
  end
end 