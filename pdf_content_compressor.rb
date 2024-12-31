class PDFContentCompressor
  def self.compress(content)
    compressed = []
    current_block = []
    in_bt_block = false
    current_text = ""

    content.each_line do |line|
      if line.include?('BT')
        in_bt_block = true
        current_block = []
        current_text = ""
      elsif line.include?('ET')
        in_bt_block = false
        current_text = current_block.join("")
        compressed << current_text unless current_text.empty?
      elsif in_bt_block && line =~ /\((.*?)\)\s*Tj/
        # Extract text between (...) followed by Tj
        text = $1.strip
        if text =~ /^(?:Non|Residenti|al|Digit|al Facil|ities)$/
          # Special handling for split text
          current_text += text
          current_block << text
        else
          if !current_text.empty?
            compressed << current_text
          end
          current_text = text
          current_block = [text]
        end
      end
    end

    compressed.reject(&:empty?).join("\n")
  end
end 