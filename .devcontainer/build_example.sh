#!/usr/bin/bash

cd /builds/flutter/examples/multiple_windows/
/builds/flutter/bin/flutter config --enable-windowing
/builds/flutter/bin/flutter build linux --release
cp /builds/flutter/engine/src/out/host_release/libflutter_linux_gtk.so build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so
# Build with local engine
# /builds/flutter/bin/flutter --local-engine=host_release --local-engine-host=host_release --local-engine-src-path=//builds/flutter/engine/src/out build linux --release

build/linux/x64/release/bundle/multiple_windows