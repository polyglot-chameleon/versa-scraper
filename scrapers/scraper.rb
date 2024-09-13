# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'logger'

# Generic item scraper
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
    collect_data fetch_html
    extract_regex
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
  def collect_data(dom_doc)
    @item = { url: self.class.send(:get_attr_val, dom_doc, @src['link_css'], 'href') || @url }

    (@src.key? 'text_css') && extract_text_sections(dom_doc)
    (@src.key? 'multivalue') && extract_multivalue(dom_doc)
    (@src.key? 'by_attr') && extract_attr_vals(dom_doc)

    @item.transform_keys(&:to_s)
  end

  # Extract regex from item
  def extract_regex
    (@src.key? 'regex') && @src['regex'].each_key do |src_var|
      get_regex_at src_var.split('__')
    end

    extract_datetime
  end

  private

  # Extract text sections
  def extract_text_sections(dom_doc)
    @src['text_css'].each_key do |section|
      html_section = dom_doc.at_css @src['text_css'][section]
      next if html_section.nil?

      @item[section] = html_section.content.strip
    end
  end

  # Extract multivalue entities
  def extract_multivalue(dom_doc)
    @src['multivalue'].each_key do |key|
      html_data_list = dom_doc.css(@src['multivalue'][key])

      @item[key] = html_data_list.map { |html_item| html_item.content.strip }
    end
  end

  # Extract attribute values
  def extract_attr_vals(dom_doc)
    @src['by_attr'].each do |by_attr|
      by_attr['attrs'].each do |attr|
        name = by_attr.key?('name') ? "#{by_attr['name']}_#{attr}" : attr
        attr_val = self.class.send(:get_attr_val, dom_doc, by_attr['css'], attr)
        @item[name] = attr_val unless attr_val.nil?
      end
    end
  end

  # Regex match on previously extracted html entity
  def get_regex_at(src_var, idx) # rubocop:disable Metrics/AbcSize
    @src['regex'][src_var].each_key do |key|
      matches = (if idx
                   @item[src_var][idx.to_i] # if multivalue entity
                 else
                   @item[src_var]
                 end).gsub(/\n|\s{2,}|\u00A0/,
                           ' ').match(@src['regex'][src_var][key]).to_a

      @item[key] = matches[matches.length % 2] # > 1 ? 1 : 0
    end
  end

  # Parse previously extracted datetime
  def extract_datetime
    (@src.key? 'datetime_fmt') && (return DateTime.strptime @item['datetime'],
                                                            @src['datetime_fmt'])

    @item['datetime'] = DateTime.parse @item['datetime']
  end

  def self.get_attr_val(dom, css, attr_name)
    node = dom.at_css css
    node && node[attr_name]
  end

  private_class_method :get_attr_val
end
