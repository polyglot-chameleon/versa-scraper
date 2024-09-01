FROM ruby:3.2.2-bookworm

RUN bundle config --global frozen 1

WORKDIR /app
COPY . /app/

RUN bundle install

CMD [ "ruby", "main.rb" ]