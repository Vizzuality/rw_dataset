FROM ruby:2.3.0
MAINTAINER Sebastian Schkudlara "sebastian.schkudlara@vizzuality.com"

RUN apt-get update -qq && apt-get install -y build-essential postgresql-client libpq-dev libxml2-dev libxslt1-dev

RUN mkdir /rw_dataset

WORKDIR /rw_dataset
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

ADD . /rw_dataset

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
