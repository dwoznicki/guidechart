require_relative "chart"

days = 0
guides = []
clients = []
for i in 0..ARGV.length
    arg = ARGV[i]
    if arg == "--days"
        days = ARGV[i+1].to_i
    elsif arg == "--guides"
        guides = ARGV[i+1].split(",")
    elsif arg == "--clients"
        clients = ARGV[i+1].split(",")
    end
end

chart = Chart.new(days, guides, clients)
chart.generate
#puts chart.to_json
puts chart.to_csv

