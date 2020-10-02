#!/bin/bash
set -e
set -x

if [[ -z $ENGINE_PATH ]]
then
  echo "Please set ENGINE_PATH environment variable."
  exit 1
fi

# Go to the engine git repo to get the date of the latest commit.
cd $ENGINE_PATH/src/flutter

# Get latest commit's time for the engine repo.
# Use date based on local time otherwise timezones might get mixed.
LATEST_COMMIT_TIME_ENGINE=`git log -1 --date=local --format="%cd"`
echo "Latest commit time on engine found as $LATEST_COMMIT_TIME_ENGINE"

if [[ -z $FLUTTER_CLONE_REPO_PATH ]]
then
  echo "Please set FLUTTER_CLONE_REPO_PATH environment variable."
  exit 1
else
  cd $FLUTTER_CLONE_REPO_PATH
fi

# Get the time of the youngest commit older than engine commit.
# Git log uses commit date not the author date.
# Before makes the comparison considering the timezone as well.
COMMIT_NO=`git log --before="$LATEST_COMMIT_TIME_ENGINE" -n 1 | grep commit | cut -d ' ' -f2`
echo "Using the flutter/flutter commit $COMMIT_NO";
git reset --hard $COMMIT_NO

# Write the commit number to a file. This file will be read by the LUCI recipe.
echo "$COMMIT_NO" >> flutter_ref.txt

# Print out the flutter version for troubleshooting
$FLUTTER_CLONE_REPO_PATH/bin/flutter --version -v
