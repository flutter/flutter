#!/bin/bash

TAG="${CIRRUS_TAG:-latest}"

# Convert "+" to "-" to make hotfix tags legal Docker tag names.
# See https://docs.docker.com/engine/reference/commandline/tag/
TAG=${TAG/+/-}

sudo docker push "gcr.io/flutter-cirrus/build-flutter-image:$TAG"
