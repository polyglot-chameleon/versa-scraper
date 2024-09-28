# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scrapers/list_scraper'

# Test paginated list scraper
class TestListScraper < Minitest::Test
  def setup
    @scraper = ListScraper.new YAML.load_file '__tests__/resources/test.yml'
    doc = Nokogiri.HTML5 File.open '__tests__/resources/item-list.html'
    @scraper.send :collect_items_from, doc
  end

  def test_collect_items
    assert_equal 5, @scraper.items.length
    @scraper.items.all? do |item|
      assert_includes item.keys, 'title' and
        assert_includes item.keys, 'description' and
        assert_includes item.keys, 'meta'
    end
  end

  def test_extract_regex
    @scraper.items.all? do |item|
      @scraper.send :extract_regex
      @scraper.src['regex'].each_key do |key|
        assert_includes item.keys, key
      end
    end
  end
end
