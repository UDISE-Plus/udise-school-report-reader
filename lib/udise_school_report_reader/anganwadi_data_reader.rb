require_relative 'data_reader_base'

class AnganwadiDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'Anganwadi At Premises' => {
      key_path: ['anganwadi', 'at_premises']
    },
    'Anganwadi Boys' => {
      key_path: ['anganwadi', 'boys'],
      value_type: :integer
    },
    'Anganwadi Girls' => {
      key_path: ['anganwadi', 'girls'],
      value_type: :integer
    },
    'Anganwadi Worker' => {
      key_path: ['anganwadi', 'worker']
    }
  }
end 