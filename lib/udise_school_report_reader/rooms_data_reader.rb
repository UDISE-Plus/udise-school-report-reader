require_relative 'data_reader_base'

class RoomsDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'In Good Condition' => {
      key_path: ['rooms', 'classrooms', 'good_condition'],
      value_type: :integer,
      end_pattern: /Needs Minor/
    },
    'Needs Minor Repair' => {
      key_path: ['rooms', 'classrooms', 'needs_minor_repair'],
      value_type: :integer,
      end_pattern: /Needs Major/
    },
    'Needs Major Repair' => {
      key_path: ['rooms', 'classrooms', 'needs_major_repair'],
      value_type: :integer,
      end_pattern: /Other Rooms/
    },
    'Other Rooms' => {
      key_path: ['rooms', 'other'],
      value_type: :integer,
      end_pattern: /Library/
    },
    'Library Availability' => {
      key_path: ['rooms', 'library'],
      end_pattern: /Solar/
    },
    'Separate Room for HM' => {
      key_path: ['rooms', 'hm'],
      end_pattern: /Drinking/
    }
  }
end 