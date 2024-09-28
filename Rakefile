# frozen_string_literal: true

task default: %w[test]

task :test do
  require_relative '__tests__/test_scraper'
  require_relative '__tests__/test_list_scraper'
  require_relative '__tests__/test_paginated_list_scraper'
end

task :coverage do
  require 'simplecov'
  SimpleCov.start do
    add_filter(/test/)
  end

  Rake::Task[:test].execute
end
