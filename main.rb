require_relative './inn_in_json.rb'
require_relative 'dadata_api'
require 'json'

dadata_api = DadataApi.new
result = dadata_api.search_by_inn_values(["7736050003"])
puts result
