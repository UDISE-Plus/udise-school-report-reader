require_relative 'data_reader_base'

class SanitationDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'Handwash Near Toilet' => {
      key_path: ['sanitation', 'handwash', 'near_toilet'],
      end_pattern: /Handwash Facility/
    },
    'Handwash Facility for Meal' => {
      key_path: ['sanitation', 'handwash', 'for_meal'],
      end_pattern: /Total Class/
    },
    'Toilets' => {
      key_path: ['sanitation', 'toilets'],
      is_table: true,
      table_config: {
        sections: [
          {
            trigger: /Total.*CWSN/,
            offset: 1,
            fields: [
              { key: ['boys', 'total'], value_type: :integer },
              { key: ['girls', 'total'], value_type: :integer }
            ]
          },
          {
            trigger: "Functional",
            offset: 1,
            fields: [
              { key: ['boys', 'functional'], value_type: :integer },
              { key: ['girls', 'functional'], value_type: :integer }
            ]
          },
          {
            trigger: /CWSN Friendly/,
            offset: 1,
            fields: [
              { key: ['boys', 'cwsn'], value_type: :integer },
              { key: ['girls', 'cwsn'], value_type: :integer }
            ]
          },
          {
            trigger: "Urinal",
            offset: 1,
            fields: [
              { key: ['boys', 'urinals'], value_type: :integer },
              { key: ['girls', 'urinals'], value_type: :integer }
            ]
          }
        ]
      }
    }
  }
end 