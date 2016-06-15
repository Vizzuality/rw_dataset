#!/bin/bash
set -e

case "$1" in
    develop)
        echo "Running Development Server"
        gem install bundler --conservative
        bundle install --without=test,production

        bundle exec rake db:create RAILS_ENV=development
        bundle exec rake db:migrate RAILS_ENV=development

        export SECRET_KEY_BASE=$(rake secret)

        rm -f tmp/pids/puma.pid
        exec ./server start develop
        ;;
    test)
        echo "Running Test"
        gem install bundler
        bundle install --without=development,production
        bundle exec rake db:create RAILS_ENV=test
        bundle exec rake db:migrate RAILS_ENV=test

        export SECRET_KEY_BASE=$(rake secret)

        rm -f tmp/pids/puma.pid
        exec rspec
        ;;
    start)
        echo "Running Start"
        gem install bundler
        bundle install --without=development,test
        bundle exec rake db:create RAILS_ENV=production
        bundle exec rake db:migrate RAILS_ENV=production

        export SECRET_KEY_BASE=$(rake secret)

        rm -f tmp/pids/puma.pid
        exec ./server start production
        ;;
    *)
        exec "$@"
esac