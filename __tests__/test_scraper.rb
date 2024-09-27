# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scrapers/scraper'

# Test paginated list scraper
class TestScraper < Minitest::Test
  def setup
    @scraper = Scraper.new YAML.load_file '__tests__/resources/test.yml'

    doc = Nokogiri.HTML5 File.open('__tests__/resources/item-list.html')
    @scraper.send :collect_data, doc
  end

  def test_css
    setup
    assert_equal 'div.item', @scraper.src['item_css']
    assert_equal 'div.title', @scraper.src['text_css']['title']
    assert_equal 'div.desc', @scraper.src['text_css']['description']
    assert_equal 'div.meta', @scraper.src['text_css']['meta']
  end

  def test_collect
    assert_equal 'Awesome title 1', @scraper.item['title']
    assert_equal '', @scraper.item['description']
    assert_equal 'New York | type2 | 2020-01-01 00:00', @scraper.item['meta']
  end

  def test_attr_val
    assert_equal  '/', @scraper.item['img_src']
  end

  def test_extract_regex
    @scraper.send :extract_regex
    assert_equal 'type2', @scraper.item['types']
    assert_equal '2020-01-01 00:00', @scraper.item['datetime']
  end
end
