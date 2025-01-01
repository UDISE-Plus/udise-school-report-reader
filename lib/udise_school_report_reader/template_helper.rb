module UdiseSchoolReportReader
  module TemplateHelper
    def self.template_path
      File.expand_path('../../../template.yml', __FILE__)
    end
  end
end 