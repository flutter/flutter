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

echo "Creating DDC test dir..."
TEST_DIR="$(mktemp -d)"

echo "Copying package sources..."
cp -r . "$TEST_DIR"

pushd "$TEST_DIR" > /dev/null 2>&1

# Hack additional dev dependencies into pubspec.yaml
#
# We can't check these in because build_runner indirectly depends on quiver,
# which introduces a circular dependency and makes pub upset.
echo "Patching pubspec..."
sed -i -e 's/#DDC_TEST://' pubspec.yaml

echo "Running pub get..."
pub get

echo "Running tests..."
pub run build_runner test -- "$@" || EXIT_CODE=$?

popd > /dev/null 2>&1

echo "Cleaning up..."
rm -rf "$TEST_DIR"

exit $EXIT_CODE
