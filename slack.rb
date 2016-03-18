# incoming-webhookのURLを記述する
ROOM_URL = ENV['ROOM_URL']
CALENDAR_URL = ENV['CALENDAR_URL']

require 'net/http'
require 'uri'
require 'json'
require 'time'

class Slack
  class << self
    def tweet_resevations
      reservations = parse_json
      today = Time.now.strftime('%Y/%m/%d')

      tweet_text = if reservations.empty?
                     <<-EOS
本日(#{today})は会議室予約がありません。

#{CALENDAR_URL}
                   EOS
                   else
                     <<-EOS
本日(#{today})の会議室予約状況です。

#{reservations.join("\n")}

#{CALENDAR_URL}
                   EOS
                   end

      post(tweet_text)
    end


    private
    def get_json
      uri = URI.join(URI.parse(CALENDAR_URL), '/calendar/reservations')
      Net::HTTP.get(uri)
    end

    def parse_json
      parsed_json = JSON.parse(get_json)
      reservations = []

      parsed_json.each do |reservation|
        start_time = Time.parse(reservation['start']).strftime('%H:%M')
        end_time = Time.parse(reservation['end']).strftime('%H:%M')
        reservation_time = "#{start_time}-#{end_time}"
        title_and_room = "#{reservation['title']}  #{reservation['room']}"
        reservations << "#{reservation_time}  #{title_and_room}"
      end

      reservations
    end

    def post(text)
      data = { "text" => text }
      request_url = ROOM_URL
      uri = URI.parse(request_url)
      Net::HTTP.post_form(uri, { "payload" => data.to_json })
    end
  end
end

Slack.tweet_resevations
