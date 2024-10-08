# frozen_string_literal: true

require_relative 'list_scraper'

# Scraper for paginated item lists
class PaginatedListScraper < ListScraper
  # Scrape contents pagewise
  def run # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    page = fetch_html 1
    n_pages = self.class.send :get_n_pages, page, @src['pagination_button_css']

    page_data = collect_items_from page
    exit if @max_datetime >= page_data.map { |p| p['datetime'] }.filter { |p| !p.nil? }.max
    create page_data

    progressbar = ProgressBar.create title: "#{@url.host} pagewise", total: n_pages

    (2..n_pages).each do |i|
      page_data = collect_items_from fetch_html i
      create page_data
      progressbar.increment
    end
  end

  private

  # Get page html content by pagination id
  #
  # `page_idx` *Integer*
  #
  # `return` *Nokogiri::HTML5::Document*
  def fetch_html(page_idx)
    paginated_url = @url
    query = Hash[URI.decode_www_form(paginated_url.query)]
    paginated_url.query = URI.encode_www_form(query.merge(@src['pagination_query'] => page_idx))

    response = HTTParty.get paginated_url, { headers: { 'Cookie' => @cookie.to_cookie_string } }
    response.get_fields('set-cookie').each { |c| @cookie.add_cookies(c) } if @cookie.length == 1

    Nokogiri.HTML5 response.body
  end

  # Get total number of pages by pagination button number
  #
  # `page` *Nokogiri::HTML5::Document*
  #
  # `pagination_button_query` *String*
  #
  # `return` *Integer*
  def self.get_n_pages(page, pagination_button_query)
    page_buttons = page.css pagination_button_query
    page_buttons.last.content.to_i
  end

  private_class_method :get_n_pages
end
