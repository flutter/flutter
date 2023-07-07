// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A settings class that can be passed to Firestore.enablePersistence() to configure Firestore persistence.
/// Only supported for Web.
class PersistenceSettings {
  /// Whether to synchronize the in-memory state of multiple tabs.
  /// Setting this to true in all open tabs enables shared access to local persistence,
  /// shared execution of queries and latency-compensated local document updates across all connected instances.
  /// To enable this mode, synchronizeTabs:true needs to be set globally in all active tabs.
  /// If omitted or set to 'false', enablePersistence() will fail in all but the first tab.
  final bool synchronizeTabs;

  /// Creates a [PersistenceSettings] instance.
  const PersistenceSettings({
    required this.synchronizeTabs,
  });
}
