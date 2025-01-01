require_relative 'data_reader_base'

class CharacteristicsReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'School Category' => {
      key_path: ['characteristics', 'category'],
      end_pattern: /Management/
    },
    'School Type' => {
      key_path: ['characteristics', 'type'],
      end_pattern: /Lowest/
    },
    'Lowest & Highest Class' => {
      key_path: ['characteristics', 'class_range'],
      end_pattern: /Pre Primary/
    },
    'Pre Primary' => {
      key_path: ['characteristics', 'pre_primary'],
      end_pattern: /Medium/
    },
    'Is Special School for CWSN?' => {
      key_path: ['characteristics', 'is_special_school'],
      end_pattern: /Availability/
    }
  }
end 