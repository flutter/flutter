#!/bin/bash
set -ex

# Download dependencies flutter
./bin/flutter --version

# Disable analytics on the bots (to avoid skewing analytics data).
./bin/flutter config --no-analytics

./bin/flutter update-packages
