require 'fibre'
require_relative 'dadata_api'
require 'json'
require_relative 'csv_writer'

def run
  output_inns = JSON.parse(File.read('output.json'))
  processed_inns = JSON.parse(File.read('processed.json')) || []
  inns = output_inns - processed_inns
  puts processed_inns.count

  trap('INT') do # add a trap block to capture the SIGINT signal
    puts 'SIGINT received. Writing processed data to file.'
    File.write('processed.json', JSON.generate(processed_inns))
    exit
  end

  begin
    dadata_api = DadataApi.new
    csv_writer = CsvWriter.new('result')

    inns.each do |inn|
      Fiber.new do
        result = dadata_api.search_by_inn(inn)
        csv_writer.write(result)
        processed_inns << inn
      end.resume
    end

    Fiber.yield

    File.write('processed.json', JSON.generate(processed_inns))
  rescue StandardError => e
    puts e
    File.write('processed.json', JSON.generate(processed_inns))

    retry
  end
end

run
