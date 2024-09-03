# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'logger'

# Generic scraper
#
# `src` *Hash*
class Scraper
  def initialize(src)
    @src = src
    @url = URI.parse @src['url']
    @cookie = HTTParty::CookieHash.new
    @cookie['User-Agent'] =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36'
    @log = Logger.new $stdout
  end

  attr_reader :src
  attr_writer :cookie

  # Scrape the contents of a page
  #
  # `return` *Hash*
  def run
    dom = fetch_html
    extract_regex collect_data dom
  end

  protected

  # Get page html content
  #
  # `return` *Nokogiri::HTML5::Document*
  def fetch_html
    while true
      begin
        response = HTTParty.get @url, { headers: { 'Cookie' => @cookie.to_cookie_string } }
        break
      rescue OpenSSL::SSL::SSLError => e # mmeeehhh
        @log.warn e.message
        sleep 1
      end
    end
    Nokogiri.HTML5 response.body
  end

  # Collect data from dom document
  #
  # `dom_doc`: *Nokogiri::HTML5::Document*
  #
  # `return` *Hash*
  def collect_data(dom_doc) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    item = { url: self.class.send(:get_url, dom_doc, @src['link_css'], 'href') || @url }

    @src['text_css'].each_key do |key|
      html_data = dom_doc.at_css(@src['text_css'][key])
      next if html_data.nil?

      item[key] = html_data.content.strip
    end

    (@src.key? 'multivalue') && @src['multivalue'].each_key do |key|
      html_data_list = dom_doc.css(@src['multivalue'][key])

      item[key] = html_data_list.map { |html_item| html_item.content.strip }
    end

    (@src.key? 'by_attr') && @src['by_attr'].each do |by_attr|
      by_attr['attrs'].each do |attr|
        name = by_attr.key?('name') ? "#{by_attr['name']}_#{attr}" : attr
        attr_value = self.class.send(:get_url, dom_doc, by_attr['css'], attr)
        item[name] = attr_value unless attr_value.nil?
      end
    end

    item.transform_keys(&:to_s)
  end

  # Extract regex from item
  #
  # `page` *Hash*
  def extract_regex(page) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    (@src.key? 'regex') && @src['regex'].each_key do |src_var|
      src_var_split, idx = src_var.split('__')
      next unless page.key? src_var_split

      @src['regex'][src_var].each_key do |key|
        matches = (if idx
                     page[src_var_split][idx.to_i]
                   else
                     page[src_var]
                   end).gsub(/\n|\s{2,}|\u00A0/,
                             ' ').match(@src['regex'][src_var][key]).to_a
        page[key] = matches[matches.length > 1 ? 1 : 0]
      rescue NoMethodError => e
        @log.warn e.message
      end
    end

    return page unless page.key?('datetime') && !page['datetime'].nil?

    page['datetime'] =
      if page.key? 'datetime_fmt'
        DateTime.strptime page['datetime'],
                          @src['datetime_fmt']
      else
        DateTime.parse page['datetime']
      end

    page
  end

  private

  def self.get_url(dom, css, attr_name)
    node = dom.at_css(css)
    node && node[attr_name]
  end

  private_class_method :get_url
end
