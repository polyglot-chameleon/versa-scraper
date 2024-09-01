# frozen_string_literal: true

require_relative 'scrapers/paginated_list_scraper'
require_relative 'scrapers/rss_scraper'

Dir['src_profiles/*.yml'].each do |fname|
  src = YAML.load_file fname
  scraper_type = if src.key? 'pagination'
                   PaginatedListScraper
                 elsif src['url'].include? 'rss'
                   RssScraper
                 else
                   ListScraper
                 end

  scraper = scraper_type.new(src)
  scraper.run
end
