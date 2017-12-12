// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart';
import 'platform_messages.dart';

/// Listens for platform messages and directs them to [BinaryMessages].
///
/// The [ServicesBinding] also registers a [LicenseEntryCollector] that exposes
/// the licenses found in the `LICENSE` file stored at the root of the asset
/// bundle, and implements the `ext.flutter.evict` service extension (see
/// [evict]).
abstract class ServicesBinding extends BindingBase {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory ServicesBinding._() => null;

  @override
  void initInstances() {
    super.initInstances();
    ui.window
      ..onPlatformMessage = BinaryMessages.handlePlatformMessage;
    initLicenses();
  }

  /// Adds relevant licenses to the [LicenseRegistry].
  ///
  /// By default, the [ServicesBinding]'s implementation of [initLicenses] adds
  /// all the licenses collected by the `flutter` tool during compilation.
  @protected
  @mustCallSuper
  void initLicenses() {
    LicenseRegistry.addLicense(_addLicenses);
  }

  static final String _licenseSeparator = '\n' + ('-' * 80) + '\n';

  Stream<LicenseEntry> _addLicenses() async* {
    final String rawLicenses = await rootBundle.loadString('LICENSE', cache: false);
    final List<String> licenses = rawLicenses.split(_licenseSeparator);
    for (String license in licenses) {
      final int split = license.indexOf('\n\n');
      if (split >= 0) {
        yield new LicenseEntryWithLineBreaks(
          license.substring(0, split).split('\n'),
          license.substring(split + 2)
        );
      } else {
        yield new LicenseEntryWithLineBreaks(const <String>[], license);
      }
    }
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();
    registerStringServiceExtension(
      // ext.flutter.evict value=foo.png will cause foo.png to be evicted from
      // the rootBundle cache and cause the entire image cache to be cleared.
      // This is used by hot reload mode to clear out the cache of resources
      // that have changed.
      name: 'evict',
      getter: () async => '',
      setter: (String value) async {
        evict(value);
      }
    );
  }

  /// Called in response to the `ext.flutter.evict` service extension.
  ///
  /// This is used by the `flutter` tool during hot reload so that any images
  /// that have changed on disk get cleared from caches.
  @protected
  @mustCallSuper
  void evict(String asset) {
    rootBundle.evict(asset);
  }
}
