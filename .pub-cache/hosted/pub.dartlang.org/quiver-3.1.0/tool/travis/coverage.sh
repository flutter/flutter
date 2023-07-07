#!/bin/bash

# Copyright 2018 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Fast fail the script on failures.
set -e

# Gather and send coverage data.
if [ "$COVERALLS_REPO_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "dev" ]; then
  pub get
  pub global activate coverage ">=0.10.0"

  OBS_PORT=9292
  echo "Collecting coverage on port $OBS_PORT..."

  # Start tests in one VM.
  echo "Starting tests..."
  dart \
    --disable-service-auth-codes \
    --enable-vm-service=$OBS_PORT \
    --pause-isolates-on-exit \
    test/all_tests.dart &

  # Run the coverage collector to generate the JSON coverage report.
  echo "Collecting coverage..."
  pub global run coverage:collect_coverage \
    --port=$OBS_PORT \
    --out=var/coverage.json \
    --wait-paused \
    --resume-isolates

  echo "Generating LCOV report..."
  pub global run coverage:format_coverage \
    --lcov \
    --in=var/coverage.json \
    --out=var/lcov.info \
    --packages=.packages \
    --report-on=lib

  echo "Uploading to Coveralls..."
  coveralls-lcov --repo-token="$COVERALLS_REPO_TOKEN" var/lcov.info
else
  echo "Not running coverage."
fi
