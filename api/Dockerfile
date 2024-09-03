FROM ruby:3.2.2-bookworm

RUN bundle config --global frozen 1

WORKDIR /api
COPY . /api

RUN bundle install

EXPOSE 4567

CMD ["ruby", "api.rb", "-e playtime"]