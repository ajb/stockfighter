require 'httparty'
require 'dotenv'
Dotenv.load

class StockFighter
  include HTTParty

  base_uri 'https://api.stockfighter.io/'
  headers({ 'X-Starfighter-Authorization' => ENV['API_KEY'] })

  def initialize(service, page)
    @options = { query: {site: service, page: page} }
  end
end

target_price = 2650
venue = 'DOHEX'
stock = 'HIH'
account = 'JAJ44313999'
lower_ask_order_id = nil

def get_quote(venue, stock)
  res = StockFighter.get(
    "/ob/api/venues/#{venue}/stocks/#{stock}/quote"
  )
end

def order_filled?(venue, stock, order_id)
  res = StockFighter.get(
    "/ob/api/venues/#{venue}/stocks/#{stock}/orders/#{order_id}"
  )

  !res['open']
end

loop do
  quote = get_quote(venue, stock)
  ask = quote['ask']
  askSize = quote['askSize']

  puts "Ask: #{ask} | Target: #{target_price}"

  next unless ask

  if ask > target_price
    if lower_ask_order_id && !order_filled?(venue, stock, lower_ask_order_id)
      puts "Still waiting on order to be filled..."
    else
      puts "Trick market maker -- make order to lower the ask."

      res = StockFighter.post(
        "/ob/api/venues/#{venue}/stocks/#{stock}/orders",
        body: {
          account: account,
          venue: venue,
          symbol: stock,
          price: ask - 25, # decrease by 25 cents
          qty: 1,
          direction: 'buy',
          orderType: 'limit'
        }.to_json
      )

      lower_ask_order_id = res['id']
    end
  else
    puts "Making a real order!"

    StockFighter.post(
      "/ob/api/venues/#{venue}/stocks/#{stock}/orders",
      body: {
        account: account,
        venue: venue,
        symbol: stock,
        price: ask,
        qty: [3333, askSize].max,
        direction: 'buy',
        orderType: 'limit'
      }.to_json
    )
  end

  sleep 5
end
