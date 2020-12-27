FROM ruby:2.7-alpine AS builder
RUN apk add --update \
  build-base
WORKDIR /usr/local/src
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'test development' && \
  bundle install

FROM ruby:2.7-alpine
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
WORKDIR /opt/sgaudit
COPY sgaudit.rb ./
RUN adduser -D sgaudit
USER sgaudit
ENTRYPOINT ["ruby", "sgaudit.rb"]
