name: Xcode - Build and Analyze

on:
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]

jobs:
  build:
    name: Build and analyse default scheme using xcodebuild command
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Set Default Scheme
        run: |
          scheme_list=$(xcodebuild -list -json | tr -d "\n")
          default=$(echo $scheme_list | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['project']['targets'][0]")
          echo $default | cat >default
          echo Using default scheme: $default
      - name: Build
        env:
          scheme: ${{ 'default' }}
        run: |
          if [ $scheme = default ]; then scheme=$(cat default); fi
          if [ "`ls -A | grep -i \\.xcworkspace\$`" ]; then filetype_parameter="workspace" && file_to_build="`ls -A | grep -i \\.xcworkspace\$`"; else filetype_parameter="project" && file_to_build="`ls -A | grep -i \\.xcodeproj\$`"; fi
          file_to_build=`echo $file_to_build | awk '{$1=$1;print}'`
          xcodebuild clean build analyze -scheme "$scheme" -"$filetype_parameter" "$file_to_build" | xcpretty && exit ${PIPESTATUS[0]}
