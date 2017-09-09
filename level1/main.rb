require 'json'
require 'date'

FILE = File.open('data.json').read

class Pricing
  def initialize(data)
    @data = JSON.parse(data)
    @cars = @data['cars']
    @rentals_cars = {}
    @data['rentals'].map do |rental|
      @rentals_cars[rental['id']] = rental.merge!(@cars.find { |e| e['id'] == rental['car_id'] })
    end
  end

  def define_price
    res = []
    @rentals_cars.each do |car|
      duration = (Date.parse(car[1]['end_date']) - Date.parse(car[1]['start_date'])).to_i + 1
      total_price = duration * car[1]['price_per_day'] + car[1]['distance'] * car[1]['price_per_km']
      res.push(id: car[0], price: total_price)
    end
    JSON.pretty_generate(rentals: res)
  end
end

result_data = Pricing.new(FILE).define_price.to_json
converted_result = JSON.parse(result_data)
File.open('output.json', 'w') { |file| file.write(converted_result) }
