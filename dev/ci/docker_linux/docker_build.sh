#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

TAG="${CIRRUS_TAG:-latest}"

# Convert "+" to "-" to make hotfix tags legal Docker tag names.
# See https://docs.docker.com/engine/reference/commandline/tag/
TAG=${TAG/+/-}

# pull to make sure we are not rebuilding for nothing
sudo docker pull "gcr.io/flutter-cirrus/build-flutter-image:$TAG"

sudo docker build "$@" --tag "gcr.io/flutter-cirrus/build-flutter-image:$TAG" .
