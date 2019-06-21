pushd $PWD
cd ../../../..
./flutter/tools/gn --ios --simulator --unoptimized
ninja -j 100 -C out/ios_debug_sim_unopt/
popd
xcodebuild -sdk iphonesimulator \
  -scheme IosUnitTests \
  -destination 'platform=iOS Simulator,name=iPhone SE,OS=12.2' \
  test