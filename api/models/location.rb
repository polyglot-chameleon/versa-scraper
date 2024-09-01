# frozen_string_literal: true

require 'geocoder'
require 'mongoid'

require_relative 'post'

# `Location` model holding `place name` and `coords`
class Location
  include Mongoid::Document
  include Geocoder::Model::Mongoid

  field :place_name, type: String
  field :coordinates, type: Array

  embedded_in :post

  geocoded_by :place_name
  after_validation :geocode

  def address
    place_name
  end
end
