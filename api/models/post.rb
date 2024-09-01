# frozen_string_literal: true

require 'mongoid'

# Generic web `Post` model
class Post
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :url, type: String

  embeds_one :location
  # validates_presence_of :location

  index({ url: 1 }, { unique: true })
end
