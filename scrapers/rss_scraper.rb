# frozen_string_literal: true

require 'rss'
require 'ruby-progressbar'

require_relative 'list_scraper'

# RSS Scraper
class RssScraper < ListScraper
  def run # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    rss = HTTParty.get @url
    feed = RSS::Parser.parse rss.body
    @src = { **@src['pagewise'], url: @src['url'] }.transform_keys(&:to_s)

    progressbar = ProgressBar.create title: 'RSS items', total: feed.items.length
    items = feed.items.map do |item|
      item_data = { title: item.title, url: item.link,
                    description: item.description, datetime: item.pubDate }.transform_keys(&:to_s)
      item_dom = Nokogiri.HTML5 HTTParty.get item.link
      progressbar.increment
      item_data.merge! collect_data item_dom
    end

    create items
  end
end
