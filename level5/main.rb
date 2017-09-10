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
      actions = format(car[1]['deductible_reduction'], duration, total_price)
      res.push(id: car[0], actions: actions)
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

  def deductible(is_deductible, duration)
    is_deductible ? (duration * 4) * 100 : 0
  end

  def driver(is_deductible, duration, price)
    deductible = is_deductible ? (duration * 4) * 100 : 0
    (price + deductible).to_i
  end

  def owner(price)
    commission_price = price * 0.3
    (price - commission_price).to_i
  end

  def insurance(price)
    commission_price = price * 0.3
    (commission_price * 0.5).to_i
  end

  def assistance(duration)
    duration * 100
  end

  def drivy(duration, price, is_deductible)
    commission_price = price * 0.3
    insurance = insurance(price)
    assistance = assistance(duration)
    deductible = deductible(is_deductible, duration)
    ((commission_price - (insurance + assistance)) + deductible).to_i
  end

  def format_json(who, type, amount)
    { who: who, type: type, amount: amount }
  end

  def format(is_deductible, duration, price)
    driver = format_json('driver', 'debit', driver(is_deductible,
                                                    duration, price))
    owner = format_json('owner', 'credit', owner(price))
    insurance = format_json('insurance', 'credit', insurance(price))
    assistance = format_json('assistance', 'credit', assistance(duration))
    drivy = format_json('drivy', 'credit', drivy(duration,
                                                 price, is_deductible))
    res = []
    res.push(driver, owner, insurance, assistance, drivy)
  end
end

result_data = Pricing.new(FILE).define_price.to_json
converted_result = JSON.parse(result_data)
File.open('output.json', 'w') { |file| file.write(converted_result) }
