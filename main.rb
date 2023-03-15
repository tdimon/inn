require 'fibre'
require_relative 'dadata_api'
require 'json'
require_relative 'csv_writer'

LIMIT_REQUESTS = 180000

def run
  limit_data = JSON.parse(File.read('limit.json'))
  if limit_data['date'] != Date.today.to_s
    limit_data['date'] = Date.today.to_s
    limit_data['request_count'] = 0
  end
  if limit_data['request_count'] >= LIMIT_REQUESTS
    return
  end

  output_inns = JSON.parse(File.read('output.json'))
  processed_inns = JSON.parse(File.read('processed.json')) || []
  inns = output_inns - processed_inns
  puts processed_inns.count

  trap('INT') do # add a trap block to capture the SIGINT signal
    puts 'SIGINT received. Writing processed data to file.'
    File.write('limit.json', JSON.generate(limit_data))
    File.write('processed.json', JSON.generate(processed_inns))
    exit
  end

  begin
    dadata_api = DadataApi.new
    csv_writer = CsvWriter.new('result')

    inns.each do |inn|
      break if limit_data['request_count'] >= LIMIT_REQUESTS

      Fiber.new do
        result = dadata_api.search_by_inn(inn)
        csv_writer.write(result)
        processed_inns << inn
        limit_data['request_count'] += 1
        Fiber.yield
      end.resume
    end

    File.write('limit.json', JSON.generate(limit_data))
    File.write('processed.json', JSON.generate(processed_inns))
  rescue StandardError => e
    puts e
    File.write('limit.json', JSON.generate(limit_data))
    File.write('processed.json', JSON.generate(processed_inns))

    retry
  end
end

run
