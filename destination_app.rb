# destination_app

# Sinatra application 

require 'erb'

$:.unshift File.join(File.dirname(__FILE__))

#----------------------------------------------------------------------

def calculate_co2(distance)
  fuel = (7840 + 10.1 * (distance - 250)) / 370
  co2 = fuel * (44/12 * 156/184)
  return fuel, co2
end

#----------------------------------------------------------------------

def distance(place0, place1, cities)
  
  radius_of_earth = 6371  # mean radius of Earth in Kilometres

  lat0  = to_radians(cities[place0]['lat'])
  long0 = to_radians(cities[place0]['long'])
  lat1  = to_radians(cities[place1]['lat'])
  long1 = to_radians(cities[place1]['long'])
  
	term0 = Math::sin(lat0) * Math::sin(lat1)
	term1 = Math::cos(lat0) * Math::cos(lat1) * Math::cos(long1 - long0)

	Math::acos(term0 + term1) * radius_of_earth
end

#----------------------------------------------------------------------

def to_radians(deg)
  deg * Math::PI / 180
end


#----------------------------------------------------------------------

def load_city_data(infile)

  cities = Hash.new
  
  open(infile, 'rb').each_line do |line|
    if line =~ /^([A-Z][A-Z])\s(.*?\S)\s+([\d\.\-\+]+)\,([\d\.\-\+]+)/
      state = $1
      city  = $2
      lat   = $3.to_f
      long  = $4.to_f
      place = "#{city}, #{state}"

      cities[place] = { 'lat' => lat, 'long' => long, 'state' => state}
    end
  end
  
  cities
end

#----------------------------------------------------------------------




class DestinationApp < Sinatra::Base

  set :root, File.dirname(__FILE__)

  set :static, true

  cities = load_city_data('US_cities.dat')
  
  get '/' do

    @city_names = cities.keys.sort

    erb :destination_form
  end

  get '/error' do
    erb :error
  end

  
  get '/destination' do

    # dates are in 2011-08-01 format
    @date_start = params['date_start']
    @date_end   = params['date_end']

    @headcount = Array.new
    @city = Array.new
    @total_kms = Array.new
    @co2_kgs = Array.new
    
    
    params['headcount'].keys.each do |key|
      if params['headcount'][key] != '' and params['city'][key] != ''
        @headcount[key.to_i] = params['headcount'][key].to_i
        @city[key.to_i] = params['city'][key]
      end
    end

    @input_params = params

    # Compute the best choice
        
    travel_kms = Hash.new

    @city.each_index do |i|
      total_km = 0
      @city.each_index do |j|
        next if @city[i] == @city[j]
        d = distance(@city[i], @city[j], cities)
        total_km += (d * @headcount[j] * 2)
      end
      travel_kms[i] = total_km.to_i
      @total_kms[i] = total_km.to_i
      fuel, co2 = calculate_co2(total_km)
      @co2_kgs[i] = co2.to_i
    end


    @str = ''
    travel_kms.keys.sort_by{ |p| travel_kms[p] }.each do |place|
      fuel, co2 = calculate_co2(travel_kms[place])
      @str << sprintf("%-25s   total km:  %d   kg CO2: %d\n", place, travel_kms[place], co2)
    end

    # Render the output template
    erb :destination
    
  end

  get '/background' do
    erb :background
  end




end