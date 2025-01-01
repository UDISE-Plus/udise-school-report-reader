require_relative 'data_reader_base'

class LocationDataReader
  include DataReaderBase

  FIELD_MAPPINGS = {
    'State' => {
      key_path: ['location', 'state'],
      end_pattern: /District/
    },
    'District' => {
      key_path: ['location', 'district'],
      end_pattern: /Block/
    },
    'Block' => {
      key_path: ['location', 'block'],
      end_pattern: /Rural/
    },
    'Rural / Urban' => {
      key_path: ['location', 'area_type'],
      end_pattern: /Cluster/
    },
    'Pincode' => {
      key_path: ['location', 'pincode']
    },
    'Ward' => {
      key_path: ['location', 'ward'],
      end_pattern: /Mohalla/
    },
    'Cluster' => {
      key_path: ['location', 'cluster'],
      end_pattern: /Ward/
    },
    'Municipality' => {
      key_path: ['location', 'municipality'],
      end_pattern: /Assembly/
    },
    'Assembly Const.' => {
      key_path: ['location', 'assembly_constituency'],
      end_pattern: /Parl/
    },
    'Parl. Constituency' => {
      key_path: ['location', 'parliamentary_constituency'],
      end_pattern: /School/
    }
  }
end 