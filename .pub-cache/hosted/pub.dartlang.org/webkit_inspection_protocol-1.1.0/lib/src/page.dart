// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../webkit_inspection_protocol.dart';

class WipPage extends WipDomain {
  WipPage(WipConnection connection) : super(connection);

  Future<WipResponse> enable() => sendCommand('Page.enable');

  Future<WipResponse> disable() => sendCommand('Page.disable');

  Future<WipResponse> navigate(String url) =>
      sendCommand('Page.navigate', params: {'url': url});

  Future<WipResponse> reload(
      {bool? ignoreCache, String? scriptToEvaluateOnLoad}) {
    var params = <String, dynamic>{};
    if (ignoreCache != null) {
      params['ignoreCache'] = ignoreCache;
    }
    if (scriptToEvaluateOnLoad != null) {
      params['scriptToEvaluateOnLoad'] = scriptToEvaluateOnLoad;
    }

    return sendCommand('Page.reload', params: params);
  }
}
