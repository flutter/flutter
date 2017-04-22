#!/bin/bash
set -e

# Install dartdoc.
pub global activate dartdoc 0.9.11

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc
(cd dev/tools; pub get)
FLUTTER_ROOT=$PWD dart dev/tools/dartdoc.dart
FLUTTER_ROOT=$PWD dart dev/tools/javadoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis and branch is master
if [ "$TRAVIS_PULL_REQUEST" = "false" ] && [ "$TRAVIS_BRANCH" = "master" ]; then
  cd dev/docs
  firebase deploy --project docs-flutter-io
else
  mkdir workingdir
  cd workingdir
  echo "Host heroku.com" >> ~/.ssh/config
  echo "   StrictHostKeyChecking no" >> ~/.ssh/config
  echo "   CheckHostIP no" >> ~/.ssh/config
  echo "   UserKnownHostsFile=/dev/null" >> ~/.ssh/config
  git clone git@heroku.com:stage-flutter.git .
  git remote rm heroku
  git remote add heroku git@heroku.com:stage-flutter.git
  yes | heroku keys:add
  yes | git push heroku master
  mkdir -p $BRANCH
  cd $BRANCH
  rm -rf .
  cp -r dev/docs .
  git add .
  git commit -m 'deploy'
  git push -f heroku master
  heroku ps:scale web=1
fi
