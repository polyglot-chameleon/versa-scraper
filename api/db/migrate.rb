# frozen_string_literal: true

require 'mongoid'
require_relative '../models/post'

def migrate
  Mongoid.load!(File.join(File.dirname(__FILE__), 'mongoid.yml'), :development)

  p Post.count.positive?
  !Post.count.positive? && Post.create_indexes
end
