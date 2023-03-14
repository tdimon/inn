require 'uri'
require 'net/http'

class DadataApi
  def initialize
    api_key = get_key
    @url = URI("https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party")
    @headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "Authorization" => "Token #{api_key}"
    }
  end

  def search_by_inn_values(inn_values)
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = true
    http.keep_alive_timeout = 60
    request = Net::HTTP::Post.new(@url)
    @headers.each { |key, value| request[key] = value }

    data = []

    inn_values.each do |inn|
      request.body = { query: inn }.to_json
      response = http.request(request)
      data << parsed_data(inn, JSON.parse(response.body))
    end

    data
  end

  private

  def get_key
    content = File.read('config.json')
    JSON.parse(content)['dadata_api_key']
  end

  def parsed_data(inn, data)
    result = []

    begin
      suggestions = data['suggestions']
    rescue StandardError => e
      puts "Error fetching suggestions: #{e.message}"
      return result
    end

    suggestions.each do |suggestion|
      org = suggestion.dig('data')
      next unless org

      result << {
        name: org.dig('name', 'short_with_opf'),
        fio: {
          surname: org.dig('fio', 'surname'),
          name: org.dig('fio', 'name'),
          patronymic: org.dig('fio', 'patronymic')
        },
        okved: org.dig('okved'),
        okveds: org.dig('okveds')&.map { |okved| okved.dig('name') },
        address: org.dig('address', 'value'),
        employee_count: org.dig('employee_count'),
        founders: org.dig('founders')&.map { |founder| founder.dig('fio') },
        managers: org.dig('managers')&.map { |manager| { fio: manager.dig('fio'), post: manager.dig('post') } },
        finance: {
          income: org.dig('finance', 'income'),
          expense: org.dig('finance', 'expense')
        },
        phones: org.dig('phones')&.map { |phone| phone.dig('data', 'source') },
        emails: org.dig('emails')&.map { |email| email.dig('data', 'source') }
      }
    end

    result
  end
end
