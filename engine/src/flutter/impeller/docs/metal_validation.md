# Enable Metal Validation without Xcode.

To enable validation of all Metal calls without using Xcode, add the following
to your rc file.

These flags are not documented and have been reverse engineered from observing
what Xcode does to enable these validation layers.


```
# Metal Tracing Defaults
export DYLD_INSERT_LIBRARIES="/usr/lib/libMTLCapture.dylib:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/GPUToolsPlatform/libMTLToolsDiagnostics.dylib"
export METAL_DEBUG_ERROR_MODE=0
export METAL_DEVICE_FORCE_COMMAND_BUFFER_ENHANCED_ERRORS=1
export METAL_DEVICE_WRAPPER_TYPE=5
export METAL_DIAGNOSTICS_ENABLED=1
export METAL_LOAD_INTERPOSER=1
export MTL_FORCE_COMMAND_BUFFER_ENHANCED_ERRORS=1
export DYMTL_TOOLS_DYLIB_PATH="/usr/lib/libMTLCapture.dylib"
```


These flags have been validated to work on macOS Monterey (12.0.1)
