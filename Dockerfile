FROM rust:1.31

WORKDIR /usr/app

# Required tools for CircleCI
# https://circleci.com/docs/2.0/custom-images/#required-tools-for-primary-containers
# 
# GHC & Cabal
# TODO specify versions
# http://downloads.haskell.org/debian/
RUN apt-get update && apt-get install -y \
    ghc \
    cabal-install