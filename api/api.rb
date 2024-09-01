# frozen_string_literal: true

require 'sinatra'

require_relative 'database/migrate'
require_relative 'models/location'

migrate

post '/' do
  content_type 'application/json'
  posts = JSON.parse request.body.read
  posts.map do |post|
    post['location'] = Location.new(place_name: post['location']).serializable_hash if post.key? 'location'
    post['datetime'] = DateTime.parse post['datetime'] unless post['datetime'].nil?
    post.delete 'meta'
  end
  Post.create posts
end

get '/' do
  content_type 'application/json'
  # Post.where({ :datetime.gt => Date.today - Date.today.wday - 14 }).to_json
  # Post.where('location.coordinates' => { '$ne' => nil }).to_json
  Post.all.to_json
end

get '/authors' do
  content_type 'application/json'
  # Post.where({ :datetime.gt => Date.today - Date.today.wday - 14 }).to_json
  # Post.where('location.coordinates' => { '$ne' => nil }).to_json
  Post.only('author').all.to_json
end

get '/latest' do
  content_type 'application/json'
  Post.where(base_url: params['src_url']).max(:datetime).to_json
end
