#!/bin/bash

TAG="${CIRRUS_TAG:-latest}"

sudo docker push "gcr.io/flutter-cirrus/build-flutter-image:$TAG"

