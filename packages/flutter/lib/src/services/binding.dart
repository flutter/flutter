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
mixin ServicesBinding on BindingBase {
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

  Stream<LicenseEntry> _addLicenses() async* {
    // We use timers here (rather than scheduleTask from the scheduler binding)
    // because the services layer can't use the scheduler binding (the scheduler
    // binding uses the services layer to manage its lifecycle events). Timers
    // are what scheduleTask uses under the hood anyway. The only difference is
    // that these will just run next, instead of being prioritized relative to
    // the other tasks that might be running. Using _something_ here to break
    // this into two parts is important because isolates take a while to copy
    // data at the moment, and if we receive the data in the same event loop
    // iteration as we send the data to the next isolate, we are definitely
    // going to miss frames. Another solution would be to have the work all
    // happen in one isolate, and we may go there eventually, but first we are
    // going to see if isolate communication can be made cheaper.
    // See: https://github.com/dart-lang/sdk/issues/31959
    //      https://github.com/dart-lang/sdk/issues/31960
    // TODO(ianh): Remove this complexity once these bugs are fixed.
    final Completer<String> rawLicenses = Completer<String>();
    Timer.run(() async {
      rawLicenses.complete(rootBundle.loadString('LICENSE', cache: false));
    });
    await rawLicenses.future;
    final Completer<List<LicenseEntry>> parsedLicenses = Completer<List<LicenseEntry>>();
    Timer.run(() async {
      parsedLicenses.complete(compute(_parseLicenses, await rawLicenses.future, debugLabel: 'parseLicenses'));
    });
    await parsedLicenses.future;
    yield* Stream<LicenseEntry>.fromIterable(await parsedLicenses.future);
  }

  // This is run in another isolate created by _addLicenses above.
  static List<LicenseEntry> _parseLicenses(String rawLicenses) {
    final String _licenseSeparator = '\n' + ('-' * 80) + '\n';
    final List<LicenseEntry> result = <LicenseEntry>[];
    final List<String> licenses = rawLicenses.split(_licenseSeparator);
    for (String license in licenses) {
      final int split = license.indexOf('\n\n');
      if (split >= 0) {
        result.add(LicenseEntryWithLineBreaks(
          license.substring(0, split).split('\n'),
          license.substring(split + 2)
        ));
      } else {
        result.add(LicenseEntryWithLineBreaks(const <String>[], license));
      }
    }
    return result;
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      registerStringServiceExtension(
        // ext.flutter.evict value=foo.png will cause foo.png to be evicted from
        // the rootBundle cache and cause the entire image cache to be cleared.
        // This is used by hot reload mode to clear out the cache of resources
        // that have changed.
        name: 'evict',
        getter: () async => '',
        setter: (String value) async {
          evict(value);
        },
      );
      return true;
    }());
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
