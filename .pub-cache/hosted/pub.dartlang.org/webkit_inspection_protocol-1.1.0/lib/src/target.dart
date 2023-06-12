// Copyright 2018 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../webkit_inspection_protocol.dart';

class WipTarget extends WipDomain {
  WipTarget(WipConnection connection) : super(connection);

  /// Creates a new page.
  ///
  /// [url] The initial URL the page will be navigated to.
  ///
  /// Returns the targetId of the page opened.
  Future<String> createTarget(String url) async {
    WipResponse response =
        await sendCommand('Target.createTarget', params: {'url': url});
    return response.result!['targetId'] as String;
  }

  /// Activates (focuses) the target.
  Future<WipResponse> activateTarget(String targetId) =>
      sendCommand('Target.activateTarget', params: {'targetId': targetId});

  /// Closes the target. If the target is a page that gets closed too.
  ///
  /// Returns `true` on success.
  Future<bool> closeTarget(String targetId) async {
    WipResponse response =
        await sendCommand('Target.closeTarget', params: {'targetId': targetId});
    return response.result!['success'] as bool;
  }

  /// Inject object to the target's main frame that provides a communication
  /// channel with browser target. Injected object will be available as
  /// `window[bindingName]`. The object has the following API:
  ///
  ///  - binding.send(json) - a method to send messages over the remote
  ///    debugging protocol
  ///  - binding.onmessage = json => handleMessage(json) - a callback that will
  ///    be called for the protocol notifications and command responses.
  @experimental
  Future<WipResponse> exposeDevToolsProtocol(
    String targetId, {
    String? bindingName,
  }) {
    final Map<String, dynamic> params = {'targetId': targetId};
    if (bindingName != null) {
      params['bindingName'] = bindingName;
    }
    return sendCommand(
      'Target.exposeDevToolsProtocol',
      params: params,
    );
  }
}
