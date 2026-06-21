FROM ruby:3.3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
  build-essential \
  postgresql-client \
  git \
  nodejs \
  yarn \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock* ./

RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
