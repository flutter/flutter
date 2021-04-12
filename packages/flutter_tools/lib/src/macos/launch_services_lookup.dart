// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Stub classes to provide typing in function declarations.
class _CFAllocator extends Struct {
  Pointer<Struct>? isa;
}

class _CFArray extends Struct {
  Pointer<Struct>? isa;
}

class _CFError extends Struct {
  Pointer<Struct>? isa;
}

class _CFString extends Struct {
  Pointer<Struct>? isa;
}

class _CFURL extends Struct {
  Pointer<Struct>? isa;
}

// FFI function declaration pairs.
typedef _CFReleaseNativeType = Void Function(Pointer object);
typedef _CFReleaseDartType = void Function(Pointer object);

typedef _CFAllocatorGetDefaultNativeType = Pointer<_CFAllocator> Function();
typedef _CFAllocatorGetDefaultDartType = Pointer<_CFAllocator> Function();

typedef _CFStringCreateWithCStringNativeType = Pointer<_CFString> Function(
  Pointer<_CFAllocator> allocator,
  Pointer<Utf8> string,
  Uint32 encoding,
);
typedef _CFStringCreateWithCStringDartType = Pointer<_CFString> Function(
  Pointer<_CFAllocator> allocator,
  Pointer<Utf8> string,
  int encoding,
);

typedef _LSCopyApplicationURLsForBundleIdentifierNativeType
    = Pointer<_CFArray> Function(
        Pointer<_CFString> bundleIdentifier, Pointer<Pointer<_CFError>> error);
typedef _LSCopyApplicationURLsForBundleIdentifierDartType
    = Pointer<_CFArray> Function(
        Pointer<_CFString> bundleIdentifier, Pointer<Pointer<_CFError>> error);

typedef _CFArrayGetCountNativeType = Int64 Function(Pointer<_CFArray> array);
typedef _CFArrayGetCountDartType = int Function(Pointer<_CFArray> array);

typedef _CFArrayGetValueAtIndexNativeType = Pointer Function(
    Pointer<_CFArray> array, Int64 index);
typedef _CFArrayGetValueAtIndexDartType = Pointer Function(
    Pointer<_CFArray> array, int index);

typedef _CFURLGetFileSystemRepresentationNativeType = Uint8 Function(
    Pointer<_CFURL> url,
    Uint8 resolveAgainstBase,
    Pointer<Utf8> buffer,
    Int64 bufferLength);
typedef _CFURLGetFileSystemRepresentationDartType = int Function(
    Pointer<_CFURL> url,
    int resolveAgainstBase,
    Pointer<Utf8> buffer,
    int bufferLength);

const String _coreFoundationLibrary =
    '/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation';
const String _coreServicesLibrary =
    '/System/Library/Frameworks/CoreServices.framework/Versions/Current/CoreServices';
const int _kCFStringEncodingUTF8 = 0x08000100;

/// A utility for querying the macOS LaunchServices database of known
/// applications.
class LaunchServicesLookup {
  LaunchServicesLookup._() {
    final DynamicLibrary coreFoundation =
        DynamicLibrary.open(_coreFoundationLibrary);
    final DynamicLibrary coreServices =
        DynamicLibrary.open(_coreServicesLibrary);

    _cfRelease = coreFoundation
        .lookup<NativeFunction<_CFReleaseNativeType>>('CFRelease')
        .asFunction<_CFReleaseDartType>();
    _cfStringCreateWithCString = coreFoundation
        .lookup<NativeFunction<_CFStringCreateWithCStringNativeType>>(
            'CFStringCreateWithCString')
        .asFunction<_CFStringCreateWithCStringDartType>();
    _cfAllocatorGetDefault = coreFoundation
        .lookup<NativeFunction<_CFAllocatorGetDefaultNativeType>>(
            'CFAllocatorGetDefault')
        .asFunction<_CFAllocatorGetDefaultDartType>();
    _cfArrayGetCount = coreFoundation
        .lookup<NativeFunction<_CFArrayGetCountNativeType>>('CFArrayGetCount')
        .asFunction<_CFArrayGetCountDartType>();
    _cfArrayGetValueAtIndex = coreFoundation
        .lookup<NativeFunction<_CFArrayGetValueAtIndexNativeType>>(
            'CFArrayGetValueAtIndex')
        .asFunction<_CFArrayGetValueAtIndexDartType>();
    _cfUrlGetFileSystemRepresentation = coreFoundation
        .lookup<NativeFunction<_CFURLGetFileSystemRepresentationNativeType>>(
            'CFURLGetFileSystemRepresentation')
        .asFunction<_CFURLGetFileSystemRepresentationDartType>();
    _lsCopyApplicationURLsForBundleIdentifier = coreServices
        .lookup<
                NativeFunction<
                    _LSCopyApplicationURLsForBundleIdentifierNativeType>>(
            'LSCopyApplicationURLsForBundleIdentifier')
        .asFunction<_LSCopyApplicationURLsForBundleIdentifierDartType>();
  }

  static LaunchServicesLookup get instance {
    _instance ??= LaunchServicesLookup._();
    return _instance!;
  }

  static LaunchServicesLookup? _instance;

  _CFReleaseDartType? _cfRelease;
  _CFStringCreateWithCStringDartType? _cfStringCreateWithCString;
  _CFAllocatorGetDefaultDartType? _cfAllocatorGetDefault;
  _CFArrayGetCountDartType? _cfArrayGetCount;
  _CFArrayGetValueAtIndexDartType? _cfArrayGetValueAtIndex;
  _CFURLGetFileSystemRepresentationDartType? _cfUrlGetFileSystemRepresentation;
  _LSCopyApplicationURLsForBundleIdentifierDartType?
      _lsCopyApplicationURLsForBundleIdentifier;

  /// Returns the paths of all copies of the application identified by
  /// [bundleIdentifier] that are known to LaunchServices.
  ///
  /// The LaunchServices database may not always be completely accurate, so
  /// callers should verify that any returned paths actually exist before trying
  /// to use them.
  List<String> pathsForBundleIdentifier(String bundleIdentifier) {
    if (_cfRelease == null ||
        _cfStringCreateWithCString == null ||
        _cfAllocatorGetDefault == null ||
        _cfArrayGetCount == null ||
        _cfArrayGetValueAtIndex == null ||
        _cfUrlGetFileSystemRepresentation == null ||
        _lsCopyApplicationURLsForBundleIdentifier == null) {
      return <String>[];
    }

    final Pointer<_CFString> bundleId = _cfStringCreateWithCString!(
      _cfAllocatorGetDefault!(),
      bundleIdentifier.toNativeUtf8(),
      _kCFStringEncodingUTF8,
    );
    final Pointer<_CFArray> urls =
        _lsCopyApplicationURLsForBundleIdentifier!(bundleId, nullptr);
    _cfRelease!(bundleId);

    final List<String> paths = <String>[];
    final int count = _cfArrayGetCount!(urls);
    if (count > 0) {
      final Pointer<_CFURL> firstUrl =
          _cfArrayGetValueAtIndex!(urls, 0).cast<_CFURL>();
      const int bufferSize = 2048;
      final Pointer<Utf8> buffer = calloc<Uint8>(bufferSize + 1).cast<Utf8>();
      final int result =
          _cfUrlGetFileSystemRepresentation!(firstUrl, 1, buffer, bufferSize);
      if (result == 1) {
        paths.add(buffer.toDartString());
      }
      calloc.free(buffer);
    }

    _cfRelease!(urls);

    return paths;
  }
}
