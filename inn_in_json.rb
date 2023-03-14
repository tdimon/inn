require 'nokogiri'
require 'json'

def save_inn_in_json_file
  xml_dir = 'xml_files'
  output_file = File.join(__dir__, 'output.json')

  inn_values = []

  Dir.foreach(xml_dir) do |file_name|
    next if ['.', '..'].include?(file_name)

    full_file_name = File.join(__dir__, xml_dir, file_name)
    xml_file = File.read(full_file_name)
    doc = Nokogiri::XML(xml_file)
    inn_values += doc.xpath('//СведНП').map { |node| node['ИННЮЛ'] }
  end

  File.write(output_file, JSON.generate(inn_values.uniq))
end
