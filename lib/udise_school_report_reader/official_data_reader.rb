require_relative 'data_reader_base'

class OfficialDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'Year of Establishment' => {
      key_path: ['official', 'established'],
      value_type: :integer
    },
    'Year of Recognition-Pri.' => {
      key_path: ['official', 'recognition', 'primary'],
      value_type: :integer
    },
    'Year of Recognition-Upr.Pri.' => {
      key_path: ['official', 'recognition', 'upper_primary'],
      value_type: :integer
    },
    'Year of Recognition-Sec.' => {
      key_path: ['official', 'recognition', 'secondary'],
      value_type: :integer
    },
    'Year of Recognition-Higher Sec.' => {
      key_path: ['official', 'recognition', 'higher_secondary'],
      value_type: :integer
    },
    'Affiliation Board-Sec' => {
      key_path: ['official', 'affiliation', 'secondary'],
      end_pattern: /Affiliation Board-HSec/
    },
    'Affiliation Board-HSec' => {
      key_path: ['official', 'affiliation', 'higher_secondary'],
      end_pattern: /Is this/
    },
    'School Management' => {
      key_path: ['official', 'management'],
      end_pattern: /School Type/
    }
  }
end 