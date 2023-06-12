// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:html';

import 'usage_impl.dart';

/// An interface to a Google Analytics session, suitable for use in web apps.
///
/// [analyticsUrl] is an optional replacement for the default Google Analytics
/// URL (`https://www.google-analytics.com/collect`).
///
/// [batchingDelay] is used to control batching behaviour. Events will be sent
/// batches of 20 after the duration is over from when the first message was
/// sent.
///
/// If [batchingDelay] is `Duration()` messages will be sent when control
/// returns to the event loop.
///
/// Batched messages are sent in batches of up to 20 messages.
class AnalyticsHtml extends AnalyticsImpl {
  AnalyticsHtml(
    String trackingId,
    String applicationName,
    String applicationVersion, {
    String? analyticsUrl,
    Duration? batchingDelay,
  }) : super(
          trackingId,
          HtmlPersistentProperties(applicationName),
          HtmlPostHandler(),
          applicationName: applicationName,
          applicationVersion: applicationVersion,
          analyticsUrl: analyticsUrl,
          batchingDelay: batchingDelay,
        ) {
    var screenWidth = window.screen!.width;
    var screenHeight = window.screen!.height;

    setSessionValue('sr', '${screenWidth}x$screenHeight');
    setSessionValue('sd', '${window.screen!.pixelDepth}-bits');
    setSessionValue('ul', window.navigator.language);
  }
}

typedef HttpRequestor = Future<HttpRequest> Function(String url,
    {String? method, dynamic sendData});

class HtmlPostHandler extends PostHandler {
  final HttpRequestor? mockRequestor;

  HtmlPostHandler({this.mockRequestor});

  @override
  String encodeHit(Map<String, String> hit) {
    var viewportWidth = document.documentElement!.clientWidth;
    var viewportHeight = document.documentElement!.clientHeight;
    return postEncode({...hit, 'vp': '${viewportWidth}x$viewportHeight'});
  }

  @override
  Future<void> sendPost(String url, List<String> batch) async {
    var data = batch.join('\n');
    Future<HttpRequest> Function(String, {String method, dynamic sendData})
        requestor = mockRequestor ?? HttpRequest.request;
    try {
      await requestor(url, method: 'POST', sendData: data);
    } on Exception {
      // Catch errors that can happen during a request, but that we can't do
      // anything about, e.g. a missing internet connection.
    }
  }

  @override
  void close() {}
}

class HtmlPersistentProperties extends PersistentProperties {
  late final Map _map;

  HtmlPersistentProperties(String name) : super(name) {
    var str = window.localStorage[name];
    if (str == null || str.isEmpty) str = '{}';
    _map = jsonDecode(str);
  }

  @override
  dynamic operator [](String key) => _map[key];

  @override
  void operator []=(String key, dynamic value) {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    window.localStorage[name] = jsonEncode(_map);
  }

  @override
  void syncSettings() {}
}
