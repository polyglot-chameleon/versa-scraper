# frozen_string_literal: true

require 'sinatra'

get '/' do
  send_file File.join('resources', 'item-list.html')
end
