#!/usr/bin/bash

cd /builds/flutter/examples/multiple_windows/
/builds/flutter/bin/flutter build linux --release
cp /builds/flutter/engine/src/out/host_release/libflutter_linux_gtk.so /builds/flutter/examples/multiple_windows/build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so
/builds/flutter/examples/multiple_windows/build/linux/x64/release/bundle