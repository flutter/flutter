import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

ffi.DynamicLibrary dlopenPlatformSpecific(String name, {String path}) {
  return Platform.isAndroid
      ? ffi.DynamicLibrary.open('libffi_tests.so')
      : ffi.DynamicLibrary.process();
}
