# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scrapers/paginated_list_scraper'

# Test paginated list scraper
class TestPaginatedListScraper < Minitest::Test
  def setup
    ENV['BASE_URL'] = ''
    ENV['TARGET_URL'] = ''

    @scraper = PaginatedListScraper.new 'div.item', { title: 'div.title', description: 'div.desc', meta: 'div.meta' },
                                        { meta: { types: /type1|type2/, places: /New (Delhi|York)/,
                                                  datetime: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}/ } },
                                        'pagination_query'
    doc = Nokogiri.HTML5 File.open('__tests__/resources/paginated-list.html')
    @page_data = @scraper.send :collect_data, doc
  end

  def test_css
    setup
    assert_equal 'div.item', @scraper.list_item_css
    assert_equal 'div.title', @scraper.text_data_css_queries[:title]
    assert_equal 'div.desc', @scraper.text_data_css_queries[:description]
    assert_equal 'div.meta', @scraper.text_data_css_queries[:meta]
  end

  def test_collect_html
    assert_equal @page_data.length, 5
    @page_data.all? do |page|
      assert_includes page.keys, :title and
        assert_includes page.keys, :description and
        assert_includes page.keys, :meta
    end
  end

  def test_extract_regex
    page_data = @scraper.send :extract_regex, @page_data

    page_data.all? do |page|
      @scraper.regex.each_key do |key|
        assert_includes page.keys, key
      end
    end
  end
end
