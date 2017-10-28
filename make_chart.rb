require "pp"
require "set"
require "json"

class Chart
    def initialize(days, guides, participants)
        @days = days
        @guides = guides
        @participants = participants
        @schedule = []
    end

    def generate
        schedule = []
        day = 0
        combinations = generate_combinations
        tried = []
        revert_day = 0
        until day > @days - 1
            schedule[day] = [] unless schedule[day]
            possible = combinations.shift
            is_available = true
            schedule[day].each do |today|
                if today.to_set.intersect?(possible.to_set)
                    is_available = false
                    break
                end
            end
            unless is_available
                tried.push possible
                if combinations.empty?
                    combinations += tried
                    for i in revert_day...schedule.length
                        combinations += schedule[i]
                        schedule[i] = nil
                    end
                    schedule.compact!
                    tried = []
                    revert_day -= 1
                    revert_day = 0 if revert_day < 0
                    day = revert_day
                end
                next
            end
            schedule[day].push possible
            combinations += tried
            tried = []
            if schedule[day].length >= @guides.length
                revert_day = day
                day += 1
            end
            combinations = generate_combinations if combinations.empty?
        end
        @schedule = normalize_schedule(schedule)
        #pp @schedule
    end

    def to_json
        output = {}
        @schedule.each_with_index do |schedule, i|
            day = "day #{i+1}"
            output[day] = []
            schedule.each do |guide, pair|
                guide_pair = {
                    guide: guide,
                    participants: pair
                }
                output[day] << guide_pair
            end
        end
        JSON.pretty_generate(output)
    end

    private
    def generate_combinations
        @participants.shuffle!
        combinations = []
        @guides.each do |guide|
            for i in 0...@participants.length
                for j in (i+1)...@participants.length
                    combinations << [guide, @participants[i], @participants[j]]
                end
            end
        end
        combinations
    end

    private
    def normalize_schedule(schedule)
        result = []
        schedule.each do |daily|
            today = {}
            @guides.each do |guide|
                daily.each do |s|
                    today[guide] = [s[1], s[2]] if s[0] == guide
                end
            end
            result << today
        end
        result
    end
end

chart = Chart.new(12, ["g1", "g2", "g3"], ["p1", "p2", "p3", "p4", "p5", "p6"])
chart.generate
puts chart.to_json

