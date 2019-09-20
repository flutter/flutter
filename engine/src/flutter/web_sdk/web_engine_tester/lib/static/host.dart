// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library test.host;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:js/js.dart';

/// A class defined in content shell, used to control its behavior.
@JS()
class _TestRunner {
  external void waitUntilDone();
}

/// Returns the current content shell runner, or `null` if none exists.
@JS()
external _TestRunner get testRunner;

/// A class that exposes the test API to JS.
///
/// These are exposed so that tools like IDEs can interact with them via remote
/// debugging.
@JS()
@anonymous
class _JSApi {
  /// Causes the test runner to resume running, as though the user had clicked
  /// the "play" button.
  external Function get resume;

  /// Causes the test runner to restart the current test once it finishes
  /// running.
  external Function get restartCurrent;

  external factory _JSApi({void resume(), void restartCurrent()});
}

/// Sets the top-level `dartTest` object so that it's visible to JS.
@JS('dartTest')
external set _jsApi(_JSApi api);

/// The iframes created for each loaded test suite, indexed by the suite id.
final Map<int, IFrameElement> _iframes = <int, IFrameElement>{};

/// Subscriptions created for each loaded test suite, indexed by the suite id.
final Map<int, List<StreamSubscription<dynamic>>> _subscriptions = <int, List<StreamSubscription<dynamic>>>{};

/// The URL for the current page.
final Uri _currentUrl = Uri.parse(window.location.href);

/// Code that runs in the browser and loads test suites at the server's behest.
///
/// One instance of this runs for each browser. When the server tells it to load
/// a test, it starts an iframe pointing at that test's code; from then on, it
/// just relays messages between the two.
///
/// The browser uses two layers of [MultiChannel]s when communicating with the
/// server:
///
///                                       server
///                                         │
///                                    (WebSocket)
///                                         │
///                    ┏━ host.html ━━━━━━━━┿━━━━━━━━━━━━━━━━━┓
///                    ┃                    │                 ┃
///                    ┃    ┌──────┬───MultiChannel─────┐     ┃
///                    ┃    │      │      │      │      │     ┃
///                    ┃   host  suite  suite  suite  suite   ┃
///                    ┃           │      │      │      │     ┃
///                    ┗━━━━━━━━━━━┿━━━━━━┿━━━━━━┿━━━━━━┿━━━━━┛
///                                │      │      │      │
///                                │     ...    ...    ...
///                                │
///                         (MessageChannel)
///                                │
///      ┏━ suite.html (in iframe) ┿━━━━━━━━━━━━━━━━━━━━━━━━━━┓
///      ┃                         │                          ┃
///      ┃         ┌──────────MultiChannel┬─────────┐         ┃
///      ┃         │          │     │     │         │         ┃
///      ┃   IframeListener  test  test  test  running test   ┃
///      ┃                                                    ┃
///      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
///
/// The host (this code) has a [MultiChannel] that splits the WebSocket
/// connection with the server. One connection is used for the host itself to
/// receive messages like "load a suite at this URL", and the rest are
/// connected to each test suite's iframe via a [MessageChannel].
///
/// Each iframe then has its own [MultiChannel] which takes its
/// [MessageChannel] connection and splits it again. One connection is used for
/// the [IframeListener], which sends messages like "here are all the tests in
/// this suite". The rest are used for each test, receiving messages like
/// "start running". A new connection is also created whenever a test begins
/// running to send status messages about its progress.
///
/// It's of particular note that the suite's [MultiChannel] connection uses the
/// host's purely as a transport layer; neither is aware that the other is also
/// using [MultiChannel]. This is necessary, since the host doesn't share memory
/// with the suites and thus can't share its [MultiChannel] with them, but it
/// does mean that the server needs to be sure to nest its [MultiChannel]s at
/// the same place the client does.
void main() {
  // This tells content_shell not to close immediately after the page has
  // rendered.
  testRunner?.waitUntilDone();

  if (_currentUrl.queryParameters['debug'] == 'true') {
    document.body.classes.add('debug');
  }

  runZoned(() {
    final MultiChannel<dynamic> serverChannel = _connectToServer();
    serverChannel.stream.listen((dynamic message) {
      if (message['command'] == 'loadSuite') {
        final int channelId = message['channel'];
        final String url = message['url'];
        final int messageId = message['id'];
        final VirtualChannel<dynamic> suiteChannel = serverChannel.virtualChannel(channelId);
        final StreamChannel<dynamic> iframeChannel = _connectToIframe(url, messageId);
        suiteChannel.pipe(iframeChannel);
      } else if (message['command'] == 'displayPause') {
        document.body.classes.add('paused');
      } else if (message['command'] == 'resume') {
        document.body.classes.remove('paused');
      } else {
        assert(message['command'] == 'closeSuite');
        _iframes.remove(message['id']).remove();

        for (StreamSubscription<dynamic> subscription in _subscriptions.remove(message['id'])) {
          subscription.cancel();
        }
      }
    });

    // Send periodic pings to the test runner so it can know when the browser is
    // paused for debugging.
    Timer.periodic(Duration(seconds: 1),
        (_) => serverChannel.sink.add(<String, String>{'command': 'ping'}));

    _jsApi = _JSApi(resume: allowInterop(() {
      if (!document.body.classes.remove('paused')) {
        return;
      }
      serverChannel.sink.add(<String, String>{'command': 'resume'});
    }), restartCurrent: allowInterop(() {
      serverChannel.sink.add(<String, String>{'command': 'restart'});
    }));
  }, onError: (dynamic error, StackTrace stackTrace) {
    print('$error\n${Trace.from(stackTrace).terse}');
  });
}

/// Creates a [MultiChannel] connection to the server, using a [WebSocket] as
/// the underlying protocol.
MultiChannel<dynamic> _connectToServer() {
  // The `managerUrl` query parameter contains the WebSocket URL of the remote
  // [BrowserManager] with which this communicates.
  final WebSocket webSocket = WebSocket(_currentUrl.queryParameters['managerUrl']);

  final StreamChannelController<dynamic> controller = StreamChannelController<dynamic>(sync: true);
  webSocket.onMessage.listen((MessageEvent message) {
    final String data = message.data;
    controller.local.sink.add(jsonDecode(data));
  });

  controller.local.stream
      .listen((dynamic message) => webSocket.send(jsonEncode(message)));

  return MultiChannel<dynamic>(controller.foreign);
}

/// Creates an iframe with `src` [url] and establishes a connection to it using
/// a [MessageChannel].
///
/// [id] identifies the suite loaded in this iframe.
StreamChannel<dynamic> _connectToIframe(String url, int id) {
  final IFrameElement iframe = IFrameElement();
  _iframes[id] = iframe;
  iframe
    ..src = url
    ..width = '1000'
    ..height = '1000';
  document.body.children.add(iframe);

  // Use this to communicate securely with the iframe.
  final MessageChannel channel = MessageChannel();
  final StreamChannelController<dynamic> controller = StreamChannelController<dynamic>(sync: true);

  // Use this to avoid sending a message to the iframe before it's sent a
  // message to us. This ensures that no messages get dropped on the floor.
  final Completer<dynamic> readyCompleter = Completer<dynamic>();

  final List<StreamSubscription<dynamic>> subscriptions = <StreamSubscription<dynamic>>[];
  _subscriptions[id] = subscriptions;

  subscriptions.add(window.onMessage.listen((dynamic message) {
    // A message on the Window can theoretically come from any website. It's
    // very unlikely that a malicious site would care about hacking someone's
    // unit tests, let alone be able to find the test server while it's
    // running, but it's good practice to check the origin anyway.
    if (message.origin != window.location.origin) {
      return;
    }

    if (message.data['href'] != iframe.src) {
      return;
    }

    message.stopPropagation();

    if (message.data['ready'] == true) {
      // This message indicates that the iframe is actively listening for
      // events, so the message channel's second port can now be transferred.
      iframe.contentWindow.postMessage('port', window.location.origin, <MessagePort>[channel.port2]);
      readyCompleter.complete();
    } else if (message.data['exception'] == true) {
      // This message from `dart.js` indicates that an exception occurred
      // loading the test.
      controller.local.sink.add(message.data['data']);
    }
  }));

  subscriptions.add(channel.port1.onMessage.listen((dynamic message) {
    controller.local.sink.add(message.data['data']);
  }));

  subscriptions.add(controller.local.stream.listen((dynamic message) async {
    await readyCompleter.future;
    channel.port1.postMessage(message);
  }));

  return controller.foreign;
}
