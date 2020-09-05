FROM rubylang/ruby:master-nightly-bionic

RUN apt update && apt install -y zsh less curl gnupg

ENV BUNDLE_PATH=/app/vendor/bundle
RUN mkdir -p /app /original $BUNDLE_PATH
RUN chown -R ubuntu /app /original $BUNDLE_PATH

WORKDIR /app

USER ubuntu

ENV SHELL=/bin/zsh
