# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scrapers/list_scraper'

# Test paginated list scraper
class TestListScraper < Minitest::Test
  def setup
    @scraper = ListScraper.new YAML.load_file '__tests__/resources/test.yml'
    doc = Nokogiri.HTML5 File.open('__tests__/resources/item-list.html')
    @items = @scraper.send :collect_items_from, doc
  end

  def test_css
    setup
    assert_equal 'div.item', @scraper.src['item_css']
    assert_equal 'div.title', @scraper.src['text_css']['title']
    assert_equal 'div.desc', @scraper.src['text_css']['description']
    assert_equal 'div.meta', @scraper.src['text_css']['meta']
  end

  def test_collect_html
    assert_equal 5, @items.length
    @items.all? do |item|
      assert_includes item.keys, 'title' and
        assert_includes item.keys, 'description' and
        assert_includes item.keys, 'meta'
    end
  end

  def test_extract_regex
    @items.all? do |item|
      @scraper.send :extract_regex, item
      @scraper.src['regex'].each_key do |key|
        assert_includes item.keys, key
      end
    end
  end
end
