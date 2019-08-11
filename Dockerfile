FROM ruby:2.6.2

ENV APP_ROOT /usr/src/unsecret_puzzle

WORKDIR $APP_ROOT

RUN apt-get update && \
  apt-get install -y sqlite3

COPY . $APP_ROOT
WORKDIR $APP_ROOT

RUN bundle install && \
  sqlite3 data.db < create_database.sqlite3

EXPOSE  9292
CMD ["rackup", "-o", "0.0.0.0"]
