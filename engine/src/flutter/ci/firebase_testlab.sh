#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

APP="$1"
if [[ -z "$APP" ]]; then
  echo "Application must be specified as the first argument to the script."
  exit 255
fi

if [[ ! -f "$APP" ]]; then
  echo "File '$APP' not found."
  exit 255
fi

GIT_REVISION="${2:-$(git rev-parse HEAD)}"
BUILD_ID="${3:-$SWARMING_TASK_ID}"

# Run the test.
# game-loop tests are meant for OpenGL apps.
# This type of test will give the application a handle to a file, and
# we'll write the timeline JSON to that file.
# See https://firebase.google.com/docs/test-lab/android/game-loop
# Pixel 4. As of this commit, this is a highly available device in FTL.
gcloud --project flutter-infra firebase test android run \
  --type game-loop \
  --app "$APP" \
  --timeout 2m \
  --results-bucket=gs://flutter_firebase_testlab \
  --results-dir="engine_scenario_test/$GIT_REVISION/$BUILD_ID" \
  --device model=flame,version=29

errors=$(gsutil cat gs://flutter_firebase_testlab/engine_scenario_test/$GIT_REVISION/$BUILD_ID/\*/logcat | grep "[FE]/flutter" | true)
if [[ ! -z $errors ]]; then
  echo "Errors detected in logcat:"
  echo "$errors"
  exit 1
fi

result_size=$(gsutil du gs://flutter_firebase_testlab/engine_scenario_test/$GIT_REVISION/$BUILD_ID/\*/game_loop_results/results_scenario_0.json | cut -d " " -f1)
if [[ $result_size == "0" ]]; then
  echo "Failed to produce a timeline."
  exit 1
fi
