require "pp"
require "json"

class Chart
    attr_reader :schedule
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
            # possible = [ "guide", "client1", "client2" ]
            possible = combinations.shift
            is_available = true
            # Make sure none of people have already been used today
            schedule[day].each do |triple|
                if (triple & possible).length > 0
                    is_available = false
                    break
                end
            end
            # Make sure client pair hasn't already been used recently
            if is_available
                check_from_day = day - (schedule.length % @participants.length)
                for i in check_from_day...schedule.length
                    schedule[i].each do |triple|
                        if (possible.include?(triple[1]) && possible.include?(triple[2]))
                            is_available = false
                            break
                        end
                    end
                    break unless is_available
                end
            end
            # Make sure clients haven't had the same guide recently
            if is_available
                check_from_day = day - 2
                check_from_day = 0 if check_from_day < 1
                for i in check_from_day...schedule.length
                    schedule[i].each do |triple|
                        next unless triple[0] == possible[0]
                        if (triple.include?(possible[1]) || triple.include?(possible[2]))
                            is_available = false
                            break
                        end
                    end
                end
            end
            unless is_available
                tried.push possible
                # If all combinations have been tried, add the tried triples
                # back into the combinations pool
                if combinations.empty?
                    combinations += tried
                    # Revert back to the revert day, clearing out schedules
                    # for each day between then and the last successful day
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
            # If available, add the guide-pair combo to the schedule
            schedule[day].push possible
            # Add the tried array back into the possible combinations pool
            combinations += tried
            tried = []
            # If the schedule for this day is complete, set the revert day to
            # today and move on to the next day
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
        @schedule.each_with_index do |daily, i|
            day = "day #{i+1}"
            output[day] = []
            daily.each do |combo|
                output[day] << combo
            end
        end
        JSON.pretty_generate(output)
    end

    def to_csv
        output = "Captain,"
        output << @guides.join(",")
        output << "\n"
        @schedule.each_with_index do |daily, i|
            line1 = [ "day #{i+1}" ]
            line2 = [ "" ]
            daily.each do |combo|
                line1 << combo[:clients][0]
                line2 << combo[:clients][1]
            end
            output << line1.join(",")+"\n"
            output << line2.join(",")+"\n"
        end
        output
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
            today = [] 
            @guides.each do |guide|
                daily.each do |s|
                    if s[0] == guide
                        today << { guide: guide, clients: [s[1], s[2]] }
                    end
                    #today[guide] = [s[1], s[2]] if s[0] == guide
                end
            end
            result << today
        end
        result
    end
end

