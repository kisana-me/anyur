FROM ruby:3.4.1
RUN apt-get update && apt-get install
RUN gem i -v 8.0.1 rails