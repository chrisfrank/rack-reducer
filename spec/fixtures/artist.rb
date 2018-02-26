require_relative 'db'

# Mock an ActiveRecord/Sequel class to 'query' a DB fixture
class Artist
  def self.all
    new DB[:artists]
  end

  def self.search(args)
    all.search(args)
  end

  def initialize(data)
    @data = data
  end

  def search(args)
    self.class.new(
      args.reduce(@data) do |data, (key, value)|
        data.select { |item| item[key].match(/#{value}/i) }
      end
    )
  end

  def all
    @data
  end
end
