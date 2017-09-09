# test
#
#

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
      duration = (Date.parse(car[1]['end_date']) -
          Date.parse(car[1]['start_date'])).to_i + 1
      price_per_day = reduction(duration, car[1]['price_per_day'])
      total_price = price_per_day + car[1]['distance'] * car[1]['price_per_km']
      res.push(id: car[0], price: total_price.to_i)
    end
    JSON.pretty_generate(rentals: res)
  end

  def reduction(duration, base_price)
    price_reduct = 0
    for days in 1..duration
      price_reduct += case
                      when days > 10
                        base_price * 0.5
                      when days > 4
                        base_price * 0.7
                      when days > 1
                        base_price * 0.9
                      else
                        base_price
                      end
    end
    price_reduct
  end
end

result_data = Pricing.new(FILE).define_price.to_json
converted_result = JSON.parse(result_data)
File.open('output.json', 'w') { |file| file.write(converted_result) }
