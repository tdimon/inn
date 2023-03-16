require 'fibre'
require_relative 'dadata_api'
require 'json'
require_relative 'csv_writer'

LIMIT_REQUESTS = 180_000

def run
  session_data = JSON.parse(File.read('session_data.json'))
  if session_data['date'] != Date.today.to_s
    session_data['date'] = Date.today.to_s
    session_data['request_count'] = 0
  end
  return if session_data['request_count'] >= LIMIT_REQUESTS

  output_inns = JSON.parse(File.read('output.json'))
  start_index = output_inns.index(session_data['last_inn']) + 1
  inns = output_inns[start_index..]
  puts inns.size

  trap('INT') do # add a trap block to capture the SIGINT signal
    puts 'SIGINT received. Writing processed data to file.'
    File.write('session_data.json', JSON.generate(session_data))
    exit
  end

  begin
    dadata_api = DadataApi.new
    csv_writer = CsvWriter.new('result')

    inns.each do |inn|
      break if session_data['request_count'] >= LIMIT_REQUESTS

      Fiber.new do
        result = dadata_api.search_by_inn(inn)
        csv_writer.write(result)
        session_data['last_inn'] = inn
        session_data['request_count'] += 1
        Fiber.yield
      end.resume
    end

    File.write('session_data.json', JSON.generate(session_data))
  rescue StandardError => e
    puts e
    File.write('session_data.json', JSON.generate(session_data))

    retry
  end
end

run
