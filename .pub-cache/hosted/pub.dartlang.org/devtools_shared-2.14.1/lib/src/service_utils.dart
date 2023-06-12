// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RegisteredService {
  const RegisteredService({
    required this.service,
    required this.title,
  });

  final String service;
  final String title;
}

/// Flutter memory service registered by Flutter Tools.
///
/// We call this service to get version information about the Flutter Android
/// memory info using Android's ADB.
const flutterMemory = RegisteredService(
  service: 'flutterMemoryInfo',
  title: 'Flutter Memory Info',
);

const flutterListViews = '_flutter.listViews';

/// Flutter engine returns estimate how much memory is used by layer/picture
/// raster cache entries in bytes.
const flutterEngineRasterCache = '_flutter.estimateRasterCacheMemory';

/// Returns a normalized vm service uri.
///
/// Removes trailing characters, trailing url fragments, and decodes urls that
/// were accidentally encoded.
///
/// For example, given a [value] of http://127.0.0.1:60667/72K34Xmq0X0=/#/vm,
/// this method will return the URI http://127.0.0.1:60667/72K34Xmq0X0=/.
///
/// Returns null if the [Uri] parsed from [value] is not [Uri.absolute]
/// (ie, it has no scheme or it has a fragment).
Uri? normalizeVmServiceUri(String value) {
  value = value.trim();

  // Clean up urls that have a devtools server's prefix, aka:
  // http://127.0.0.1:9101?uri=http%3A%2F%2F127.0.0.1%3A56142%2FHOwgrxalK00%3D%2F
  const uriParamToken = '?uri=';
  if (value.contains(uriParamToken)) {
    value = value.substring(
      value.indexOf(uriParamToken) + uriParamToken.length,
    );
  }

  // Cleanup encoded urls likely copied from the uri of an existing running
  // DevTools app.
  if (value.contains('%3A%2F%2F')) {
    value = Uri.decodeFull(value);
  }
  final uri = Uri.parse(value.trim()).removeFragment();
  if (!uri.isAbsolute) {
    return null;
  }
  if (uri.path.endsWith('/')) return uri;
  return uri.replace(path: uri.path);
}
