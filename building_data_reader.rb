require_relative 'data_reader_base'

class BuildingDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'Building Status' => {
      key_path: ['building', 'status'],
      end_pattern: /Boundary/
    },
    'Boundary wall' => {
      key_path: ['building', 'boundary_wall'],
      end_pattern: /No\.of/
    },
    'No.of Building Blocks' => {
      key_path: ['building', 'blocks'],
      value_type: :integer
    },
    'Pucca Building Blocks' => {
      key_path: ['building', 'pucca_blocks'],
      value_type: :integer
    },
    'Is this a Shift School?' => {
      key_path: ['building', 'has_shifts'],
      end_pattern: /Building/
    },
    'Availability of Ramps' => {
      key_path: ['building', 'accessibility', 'ramps'],
      end_pattern: /Availability of Hand/
    },
    'Availability of Handrails' => {
      key_path: ['building', 'accessibility', 'handrails'],
      end_pattern: /Anganwadi/
    }
  }
end 