#!/bin/bash
set -e

echo $KEY_FILE | base64 --decode > ../gcloud_key_file.json

set -x

if [ -n "$TRAVIS" ]; then
  # Only used to upload docs. Don't install gcloud SDK otherwise.
  if [ "$TRAVIS_OS_NAME" = "linux" ] && [ "$SHARD" = "docs" ]; then
    export CLOUDSDK_CORE_DISABLE_PROMPTS=1
    echo "Installing Google Cloud SDK..."
    curl https://sdk.cloud.google.com | bash > /dev/null
    echo "Google Cloud SDK installation completed."
  fi

  # Android SDK only needed to build the gallery on build_and_deploy_gallery Linux shard.
  if [ "$TRAVIS_OS_NAME" = "linux" ] && [ "$SHARD" = "build_and_deploy_gallery" ]; then
    # Background for not using Travis's built-in Android tags
    # https://github.com/flutter/plugins/pull/145
    # Copied from https://github.com/flutter/plugins/blame/master/.travis.yml
    wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
    mkdir android-sdk
    unzip -qq sdk-tools-linux-3859397.zip -d android-sdk
    export ANDROID_HOME=`pwd`/android-sdk
    export PATH=`pwd`/android-sdk/tools/bin:$PATH
    mkdir -p /home/travis/.android # silence sdkmanager warning
    echo 'count=0' > /home/travis/.android/repositories.cfg # silence sdkmanager warning
    # suppressing output of sdkmanager to keep log under 4MB (travis limit)
    echo y | sdkmanager "tools" >/dev/null
    echo y | sdkmanager "platform-tools" >/dev/null
    echo y | sdkmanager "build-tools;26.0.3" >/dev/null
    echo y | sdkmanager "platforms;android-26" >/dev/null
    echo y | sdkmanager "extras;android;m2repository" >/dev/null
    echo y | sdkmanager "extras;google;m2repository" >/dev/null
    echo y | sdkmanager "patcher;v4" >/dev/null
    sdkmanager --list
    wget http://services.gradle.org/distributions/gradle-4.1-bin.zip
    unzip -qq gradle-4.1-bin.zip
    export GRADLE_HOME=$PWD/gradle-4.1
    export PATH=$GRADLE_HOME/bin:$PATH
    gradle -v
    ./bin/flutter doctor
  fi
fi

# disable analytics on the bots and download Flutter dependencies
./bin/flutter config --no-analytics

# run pub get in all the repo packages
./bin/flutter update-packages
