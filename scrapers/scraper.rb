# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'logger'

# Generic scraper
class Scraper
  def initialize(source)
    @src = source
    @url = URI.parse @src['url']
    @cookie = HTTParty::CookieHash.new
    @cookie['lang'] = 'en'
    @log = Logger.new $stdout
  end

  attr_reader :src

  def run
    dom = get_page
    extract_content_from collect_html_from dom
  end

  protected

  def collect_html_from(dom_fragment) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    item = { url: self.class.send(:get_url, dom_fragment, @src['link_css'], 'href') || @url }

    @src['text_css'].each_key do |key|
      html_data = dom_fragment.at_css(@src['text_css'][key])
      next if html_data.nil?

      item[key] = html_data.content.strip
    end

    (@src.key? 'multivalue') && @src['multivalue'].each_key do |key|
      html_data_list = dom_fragment.css(@src['multivalue'][key])

      item[key] = html_data_list.map { |html_item| html_item.content.strip }
    end

    (@src.key? 'by_attr') && @src['by_attr'].each do |by_attr|
      by_attr['attrs'].each do |attr|
        name = by_attr.key?('name') ? "#{by_attr['name']}_#{attr}" : attr
        attr_value = self.class.send(:get_url, dom_fragment, by_attr['css'], attr)
        item[name] = attr_value unless attr_value.nil?
      end
    end

    item.transform_keys(&:to_s)
  end

  # Do some processing
  def extract_content_from(page) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    (@src.key? 'regex') && @src['regex'].each_key do |src_var|
      src_var_split, idx = src_var.split('__')
      next unless page.key? src_var_split

      @src['regex'][src_var].each_key do |key|
        matches = (idx ? page[src_var_split][idx.to_i] : page[src_var]).gsub(/\n|\s{2,}|\u00A0/,
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

  # Get page of paginated list by index
  def get_page
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

  private

  def self.get_url(dom, css, attr_name)
    node = dom.at_css(css)
    node && node[attr_name]
  end

  private_class_method :get_url
end
