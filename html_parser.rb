require 'nokogiri'
require 'capybara'
require 'capybara/poltergeist'

module HTMLParser
  def self.html_include_js_contents
    session = Capybara::Session.new(:poltergeist)
    session.driver.headers = { 'User-Agent' => ENV['USER_AGENT'] }
    session.visit ENV['CALENDAR_URL']

    session.html
  end

  def self.reservations
    parsed_html = Nokogiri::HTML.parse(html_include_js_contents)
    nodes = parsed_html.css('thead > tr > td.fc-today')

    if nodes.empty?
      return []
    end

    node = nodes.first
    # 今日の日付のtd要素はtr内で何番目の要素かを取得(番号付けは0からではなく1から始まる)。
    element_num = node.path.match(/td\[(.+)\]/)[1].to_i
    # element_num より前で、 rowspan を使って作成された空のtdの数
    blank_count = 0
    # 今日の日付の週の全ての予約。
    trs = node.parent.parent.parent.css('tbody > tr')
    first_tr = trs.first

    first_tr.children.each_with_index do |td, index|
      break if (index + 1) >= element_num

      if td.attr('rowspan')
        # 今日の会議室の予約が空の場合
        if (index + 1) == element_num
          return ['今日の会議室の予約はありません']
        else
          blank_count += 1
        end
      end
    end

    reservations = []
    trs.each_with_index do |tr, index|
      # 初めの行の場合、属性 rowspan があるtd要素が存在するため、
      # 予約が空白の日を考慮しない。
      child_num = index.zero? ? element_num : (element_num - blank_count)
      reservation = tr.css("td:nth-child(#{child_num})")

      unless reservation.empty?
        reservations << reservation.text
      end
    end

    reservations
  end
end
