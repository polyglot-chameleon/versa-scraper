# frozen_string_literal: true

require_relative 'scraper'

# Scraper for paginated item lists
class ListScraper < Scraper
  def initialize(source)
    super source
    resp = HTTParty.get URI.join ENV['API_URL'], '/latest', "?src_url=#{@url.host}"
    @max_datetime = resp.body != 'null' ? DateTime.parse(resp.body) : DateTime.new

    @items = []
  end

  # Scrape the contents of a page
  #
  # overrides super
  def run
    collect_items_from fetch_html
    create
  end

  protected

  # Process and collect data from all dom list items
  def collect_items_from(doc)
    dom_items = doc.css @src['item_css']

    dom_items.each_with_index do |dom_item, idx|
      collect_data dom_item
      extract_regex if @src['text_css'].key? 'meta'
      @items[idx] = @item
    end

    pagewise dom_items if @src.key? 'pagewise'
  end

  # Fetch data on individual page
  def pagewise(dom_items)
    (0..dom_items.length - 1).each do |idx|
      page_src = { 'url' => @items[idx][:url].strip }
      next if page_src['url'] == '#'

      page_src.merge!(**@src['pagewise'])

      page_scraper = Scraper.new page_src
      page_scraper.run
      @items[idx].merge! page_scraper.item
    end
  end

  # Create posts
  def create
    HTTParty.post ENV['API_URL'],
                  { body: @items.to_json,
                    headers: { 'Content-Type' => 'application/json' } }
  end
end
