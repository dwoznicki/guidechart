require_relative "chart"
require "pp"

days = 6
guides = ["Jose", "Rodalfo", "Nestor", "Danny"]
clients = ["BobW", "BobV", "EdK", "EdM", "Linda", "Jack", "Dwayne", "Dennis"]

chart = Chart.new(days, guides, clients)
chart.generate
# Check chart
failures = []
existing_combinations = []
chart.schedule.each_with_index do |daily, i|
    daily.each do |combo|
        if existing_combinations.include? combo[:clients]
            failures << "\e[31mday #{i+1}: #{combo[:clients]} already exists\e[0m"
        else
            existing_combinations << combo[:clients]
        end
    end
end
puts "Failures:"
failures.each do |failure|
    puts failure
end
puts "Chart:"
pp chart.schedule

