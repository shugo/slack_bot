# incoming-webhookのURLを記述する
ROOM_URL = ENV['ROOM_URL']
CALENDAR_URL = ENV['CALENDAR_URL']

require 'net/http'
require 'uri'
require 'json'
require 'date'

require_relative './html_parser'

class Slack
  def self.post(text)
    data = { "text" => text }
    request_url = ROOM_URL
    uri = URI.parse(request_url)
    Net::HTTP.post_form(uri, {"payload" => data.to_json})
  end

  def self.tweet_resevations
    reservations = HTMLParser.reservations
    today = Date.today.strftime('%Y/%m/%d')

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
end

Slack.tweet_resevations
