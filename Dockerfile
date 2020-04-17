FROM ruby:latest

ENV APP_HOME /app
ENV RACK_ENV production
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
ADD *gemspec $APP_HOME/
ADD config.ru $APP_HOME/
ADD lib $APP_HOME/lib/

RUN bundle install --without development

ADD public $APP_HOME/public/

EXPOSE 9292/tcp
CMD ["bundle", "exec", "rackup"]
