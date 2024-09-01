# frozen_string_literal: true

require_relative 'list_scraper'

# Scraper for paginated item lists
class PaginatedListScraper < ListScraper
  # Run scraper
  def run # rubocop:disable Metrics/AbcSize
    page = get_page 1
    n_pages = self.class.send :get_n_pages, page, @src['pagination']['button_css']
    progressbar = ProgressBar.create title: "#{@url.host} pagewise", total: n_pages

    (1..n_pages).each do |i|
      @cur_page_idx = i
      page_data = collect_items_from get_page i

      break if @max_datetime >= page_data.map { |p| p['datetime'] }.filter { |p| !p.nil? }.max

      create page_data
      progressbar.increment
    end
  end

  private

  def get_page(page_idx) # rubocop:disable Metrics/AbcSize
    paginated_url = URI.parse @url.to_s # copying url for modification
    if @src['pagination']['type'] == 'query'
      paginated_url.query = { @src['pagination']['value'] => page_idx }
    else
      paginated_url.path += @src['pagination']['value'] + page_idx.to_s
    end
    response = HTTParty.get paginated_url,
                            { headers: { 'Cookie' => @cookie.to_cookie_string } }
    Nokogiri.HTML5 response.body
  end

  # Get total number of pages by pagination button number
  def self.get_n_pages(page, pagination_button_query)
    page_buttons = page.css pagination_button_query
    page_buttons.last.content.to_i
  end

  private_class_method :get_n_pages
end
