#!/bin/bash
rm -f build/app/outputs/bundle/release/app-release.apks
flutter build appbundle

java -jar $1 build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=build/app/outputs/bundle/release/app-release.apks --local-testing
java -jar $1 install-apks --apks=build/app/outputs/bundle/release/app-release.apks

adb shell "
am start -n com.example.deferred_components_test/com.example.deferred_components_test.MainActivity
$q
"

if ! adb logcat -s "flutter" | grep -q "Running deferred code"; then
  exit 1
fi
exit 0