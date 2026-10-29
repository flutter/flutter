// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';

/// Generates a self-unregistering `flutter_service_worker.js` cleanup stub
/// so browsers upgrading from older Flutter releases (`<= 3.38`) that had
/// an active caching service worker can update, unregister the old worker,
/// and purge legacy caches instead of getting stuck on a 404.
String generateServiceWorker(String fileGeneratorsPath, {required FileSystem fileSystem}) {
  final String flutterServiceWorkerJsPath = fileSystem.path.join(
    fileGeneratorsPath,
    'js',
    'flutter_service_worker.js',
  );
  return fileSystem.file(flutterServiceWorkerJsPath).readAsStringSync();
}
