#!/usr/bin/env bash

rm -f build/app/outputs/bundle/release/app-release.apks
rm -f build/app/outputs/bundle/release/run_logcat.log

flutter build appbundle

java -jar $1 build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=build/app/outputs/bundle/release/app-release.apks --local-testing
java -jar $1 install-apks --apks=build/app/outputs/bundle/release/app-release.apks

adb shell "
am start -n io.flutter.integration.deferred_components_test/.MainActivity
sleep 12
exit
"
adb logcat -d -s "flutter" > build/app/outputs/bundle/release/run_logcat.log
echo ""
if cat build/app/outputs/bundle/release/run_logcat.log | grep -q "Running deferred code"; then
  echo "All tests passed."
  exit 0
fi
echo "Failure: Deferred component did not load."
exit 1