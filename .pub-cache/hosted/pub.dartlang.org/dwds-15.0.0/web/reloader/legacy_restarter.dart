// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'restarter.dart';

class LegacyRestarter implements Restarter {
  @override
  Future<bool> restart({String? runId}) async {
    final dartLibrary = context['dart_library'] as JsObject;
    if (runId == null) {
      dartLibrary.callMethod('reload');
    } else {
      dartLibrary.callMethod('reload', [
        JsObject.jsify({'runId': runId})
      ]);
    }
    final reloadCompleter = Completer<bool>();
    final sub = window.onMessage.listen((event) {
      final message = event.data;
      if (message is Map &&
          message['type'] == 'DDC_STATE_CHANGE' &&
          message['state'] == 'restart_end') {
        reloadCompleter.complete(true);
      }
    });
    return reloadCompleter.future.then((value) {
      sub.cancel();
      return value;
    });
  }
}
