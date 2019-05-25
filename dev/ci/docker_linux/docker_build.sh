#!/bin/bash

TAG="${CIRRUS_TAG:-latest}"

# pull to make sure we are not rebuilding for nothing
sudo docker pull "gcr.io/flutter-cirrus/build-flutter-image:$TAG"

sudo docker build "$@" --tag "gcr.io/flutter-cirrus/build-flutter-image:$TAG" .
