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

  # Scrape the contents of a page
  def run
    page_data = collect_items_from fetch_html
    create page_data
  end

  protected

  # Process and collect data from all dom list items
  #
  # `doc` *Nokogiri::HTML5::Document*
  def collect_items_from(doc)
    page_data = []
    dom_items = doc.css @src['item_css']

    dom_items.each_with_index do |dom_item, idx|
      html_data = collect_data dom_item
      html_data = extract_regex html_data if @src['text_css'].key? 'meta'
      page_data[idx] = html_data
    end

    return page_data unless @src.key? 'pagewise'

    # Fetch data on individual page
    progressbar = ProgressBar.create title: "Page #{@cur_page_idx}", total: dom_items.length

    (0..dom_items.length - 1).each do |idx|
      page_src = {}
      page_src['url'] = @url.host + page_data[idx]['url']
      page_src.merge!(**@src['pagewise'])

      page_scraper = Scraper.new page_src
      page_scraper.cookie = @cookie
      page_data[idx].merge! page_scraper.run
      progressbar.increment
    end

    page_data
  end

  # Create posts via API
  #
  # `posts` *Array*
  def create(posts)
    HTTParty.post ENV['API_URL'],
                  { body: posts.to_json,
                    headers: { 'Content-Type' => 'application/json' } }
  end
end
