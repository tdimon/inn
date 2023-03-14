require 'csv'
require 'fileutils'

class CsvWriter
  MAX_FILE_SIZE = 5_000_000 # 5 MB in bytes

  def initialize(dir)
    @dir = dir
    FileUtils.mkdir_p(@dir) unless Dir.exist?(@dir) # Create directory if it does not exist
    @filename = last_file # Get the last filename
    if @filename && File.size(@filename) > MAX_FILE_SIZE
      @filename = nil
    end
    if @filename.nil?
      @filename = generate_filename # Generate the first filename
      write_headers # Write the headers to the file when the instance is created
    end
    @file = CSV.open(@filename, 'ab', col_sep: '|') # Open the file for writing
  end

  def write(data)
    rows = data.map do |row|
      [
        row[:inn],
        row[:name_org],
        row[:fio][:surname],
        row[:fio][:name],
        row[:fio][:patronymic],
        row[:okved],
        row[:okveds].join(','),
        row[:address],
        row[:employee_count],
        row[:founders].join(','),
        row[:managers].join(','),
        row[:finance][:income],
        row[:finance][:expense],
        row[:phones].join(','),
        row[:emails].join(',')
      ]
    end

    if @file.pos + rows.to_csv.bytesize > MAX_FILE_SIZE
      @file.close
      @filename = generate_filename
      write_headers
      @file = CSV.open(@filename, 'ab', col_sep: '|')
    end

    rows.each { |row| @file << row }
  end

  private

  def write_headers
    headers = ['INN', 'NameOrg', 'Surname', 'Name', 'Patronymic', 'Okved', 'Okveds',
               'Address', 'Employee Count', 'Founders', 'Managers', 'Income',
               'Expense', 'Phones', 'Emails']
    CSV.open(@filename, 'wb', col_sep: '|') do |csv|
      csv << headers
    end
  end

  def generate_filename
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    File.join(@dir, "result_#{timestamp}.csv")
  end

  def last_file
    Dir.glob(File.join(@dir, "*.csv")).max_by {|f| File.mtime(f)}
  end
end
