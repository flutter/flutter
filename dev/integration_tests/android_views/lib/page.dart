// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

/// The base class of all the testing pages
//
/// A testing page has to override this in order to be put as one of the items in the main page.
abstract class Page extends StatelessWidget {
  const Page(this.title, this.tileKey);

  /// The title of the testing page
  ///
  /// It will be shown on the main page as the text on the link which opens the page.
  final String title;

  /// The key of the ListTile that navigates to the page.
  ///
  /// Used by the integration test to navigate to the corresponding page.
  final ValueKey<String> tileKey;
}

/// Wraps a flutter driver [DataHandler] with one that waits until a delegate is set.
///
/// This allows the driver test to call [FlutterDriver.requestData] before the handler was
/// set by the app in which case the requestData call will only complete once the app is ready
/// for it.
class FutureDataHandler {
  Completer<DataHandler> handlerCompleter = Completer<DataHandler>();

  Future<String> handleMessage(String message) async {
    final DataHandler handler = await handlerCompleter.future;
    return handler(message);
  }

  void complete(FutureOr<DataHandler> value) {
    handlerCompleter.complete(value);
    handlerCompleter = Completer<DataHandler>();
  }
}

FutureDataHandler driverDataHandler = FutureDataHandler();