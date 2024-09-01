# frozen_string_literal: true

require 'ruby-progressbar'
require_relative 'scraper'

# Scraper for paginated item lists
class ListScraper < Scraper
  def initialize(source)
    super source
    api_url = URI.join ENV['API_URL'], '/latest', "?src_url=#{@url.host}"
    resp = HTTParty.get api_url
    @max_datetime = resp.body != 'null' ? DateTime.parse(resp.body) : DateTime.new
    @cur_page_idx = 1
  end

  # Run scraper
  def run
    page_data = collect_items_from get_page
    create page_data
  end

  protected

  # Collects data by css queries into `Nokogiri::Document` objects
  def collect_items_from(doc) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    page_data = []
    dom_items = doc.css @src['item_css']

    # progressbar = ProgressBar.create title: @url.host, total: dom_items.length

    dom_items.each_with_index do |dom_item, idx|
      html_data = collect_html_from dom_item
      html_data = extract_content_from html_data if @src['text_css'].key? 'meta'
      page_data[idx] = html_data
      # progressbar.increment
    end

    return page_data unless @src.key? 'pagewise'

    progressbar = ProgressBar.create title: "Page #{@cur_page_idx}", total: dom_items.length

    (0..dom_items.length - 1).each do |idx|
      page_src = {}
      page_src['url'] = page_data[idx]['url']
      page_src.merge!(**@src['pagewise'])
      page_scraper = Scraper.new page_src
      page_data[idx].merge! page_scraper.run
      progressbar.increment
    end

    page_data
  end

  # populate db
  def create(posts)
    HTTParty.post ENV['API_URL'],
                  { body: posts.to_json,
                    headers: { 'Content-Type' => 'application/json' } }
  end
end
