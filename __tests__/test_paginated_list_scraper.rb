# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scrapers/paginated_list_scraper'

# Test paginated list scraper
class TestPaginatedListScraper < Minitest::Test
  def setup
    @scraper = PaginatedListScraper.new YAML.load_file '__tests__/resources/test.yml'
  end

  def test_count_pages
    page = @scraper.send :fetch_html, 1
    n_pages = PaginatedListScraper.send :get_n_pages, page, @scraper.src['pagination_button_css']

    assert_equal n_pages, 3
  end
end
