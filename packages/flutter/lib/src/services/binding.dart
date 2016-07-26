// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart';
import 'shell.dart';

/// Ensures that the [MojoShell] singleton is created synchronously
/// during binding initialization. This allows other binding classes
/// to register services in the same call stack as the services are
/// offered to the embedder, thus avoiding any potential race
/// conditions. For example, without this, the embedder might have
/// requested a service before the Dart VM has started running; if the
/// [MojoShell] is then created in an earlier call stack than the
/// server for that service is provided, then the request will be
/// rejected as not matching any registered servers.
///
/// The ServicesBinding also registers a [LicenseEntryCollector] that exposes
/// the licenses found in the LICENSE file stored at the root of the asset
/// bundle.
abstract class ServicesBinding extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    new MojoShell();
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
}
