// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This test is run using `flutter drive` by the CI (see /script/tool/README.md
// in this repository for details on driving that tooling manually), but can
// also be run using `flutter test` directly during development.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/src/common/instance_manager.dart';
import 'package:webview_flutter_wkwebview/src/common/weak_reference_utils.dart';
import 'package:webview_flutter_wkwebview/src/web_kit/web_kit.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
  server.forEach((HttpRequest request) {
    if (request.uri.path == '/hello.txt') {
      request.response.writeln('Hello, world.');
    } else if (request.uri.path == '/secondary.txt') {
      request.response.writeln('How are you today?');
    } else if (request.uri.path == '/headers') {
      request.response.writeln('${request.headers}');
    } else if (request.uri.path == '/favicon.ico') {
      request.response.statusCode = HttpStatus.notFound;
    } else {
      fail('unexpected request: ${request.method} ${request.uri}');
    }
    request.response.close();
  });
  final String prefixUrl = 'http://${server.address.address}:${server.port}';
  final String primaryUrl = '$prefixUrl/hello.txt';
  final String secondaryUrl = '$prefixUrl/secondary.txt';
  final String headersUrl = '$prefixUrl/headers';

  testWidgets(
      'withWeakReferenceTo allows encapsulating class to be garbage collected',
      (WidgetTester tester) async {
    final Completer<int> gcCompleter = Completer<int>();
    final InstanceManager instanceManager = InstanceManager(
      onWeakReferenceRemoved: gcCompleter.complete,
    );

    ClassWithCallbackClass? instance = ClassWithCallbackClass();
    instanceManager.addHostCreatedInstance(instance.callbackClass, 0);
    instance = null;

    // Force garbage collection.
    await IntegrationTestWidgetsFlutterBinding.instance
        .watchPerformance(() async {
      await tester.pumpAndSettle();
    });

    final int gcIdentifier = await gcCompleter.future;
    expect(gcIdentifier, 0);
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets(
    'WKWebView is released by garbage collection',
    (WidgetTester tester) async {
      final Completer<void> webViewGCCompleter = Completer<void>();

      late final InstanceManager instanceManager;
      instanceManager =
          InstanceManager(onWeakReferenceRemoved: (int identifier) {
        final Copyable instance =
            instanceManager.getInstanceWithWeakReference(identifier)!;
        if (instance is WKWebView && !webViewGCCompleter.isCompleted) {
          webViewGCCompleter.complete();
        }
      });

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              WebKitWebViewWidgetCreationParams(
                instanceManager: instanceManager,
                controller: PlatformWebViewController(
                  WebKitWebViewControllerCreationParams(
                    instanceManager: instanceManager,
                  ),
                ),
              ),
            ).build(context);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(Container());

      // Force garbage collection.
      await IntegrationTestWidgetsFlutterBinding.instance
          .watchPerformance(() async {
        await tester.pumpAndSettle();
      });

      await expectLater(webViewGCCompleter.future, completes);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets('loadRequest', (WidgetTester tester) async {
    final Completer<void> pageFinished = Completer<void>();

    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )..setOnPageFinished((_) => pageFinished.complete()),
      )
      ..loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageFinished.future;

    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  });

  testWidgets('runJavaScriptReturningResult', (WidgetTester tester) async {
    final Completer<void> pageFinished = Completer<void>();

    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )..setOnPageFinished((_) => pageFinished.complete()),
      )
      ..loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageFinished.future;

    await expectLater(
      controller.runJavaScriptReturningResult('1 + 1'),
      completion(2),
    );
  });

  testWidgets('loadRequest with headers', (WidgetTester tester) async {
    final Map<String, String> headers = <String, String>{
      'test_header': 'flutter_test_header'
    };

    final StreamController<String> pageLoads = StreamController<String>();

    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(
        WebKitNavigationDelegate(
          const WebKitNavigationDelegateCreationParams(),
        )..setOnPageFinished((String url) => pageLoads.add(url)),
      )
      ..loadRequest(
        LoadRequestParams(
          uri: Uri.parse(headersUrl),
          headers: headers,
        ),
      );

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageLoads.stream.firstWhere((String url) => url == headersUrl);

    final String content = await controller.runJavaScriptReturningResult(
      'document.documentElement.innerText',
    ) as String;
    expect(content.contains('flutter_test_header'), isTrue);
  });

  testWidgets('JavascriptChannel', (WidgetTester tester) async {
    final Completer<void> pageFinished = Completer<void>();
    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(
        WebKitNavigationDelegate(
          const WebKitNavigationDelegateCreationParams(),
        )..setOnPageFinished((_) => pageFinished.complete()),
      );

    final Completer<String> channelCompleter = Completer<String>();
    await controller.addJavaScriptChannel(
      JavaScriptChannelParams(
        name: 'Echo',
        onMessageReceived: (JavaScriptMessage message) {
          channelCompleter.complete(message.message);
        },
      ),
    );

    controller.loadHtmlString(
      'data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+',
    );

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageFinished.future;

    await controller.runJavaScript('Echo.postMessage("hello");');
    await expectLater(channelCompleter.future, completion('hello'));
  });

  testWidgets('resize webview', (WidgetTester tester) async {
    final Completer<void> buttonTapResizeCompleter = Completer<void>();
    final Completer<void> onPageFinished = Completer<void>();

    bool resizeButtonTapped = false;
    await tester.pumpWidget(ResizableWebView(
      onResize: () {
        if (resizeButtonTapped) {
          buttonTapResizeCompleter.complete();
        }
      },
      onPageFinished: () => onPageFinished.complete(),
    ));

    await onPageFinished.future;

    resizeButtonTapped = true;

    await tester.tap(find.byKey(const ValueKey<String>('resizeButton')));
    await tester.pumpAndSettle();

    await expectLater(buttonTapResizeCompleter.future, completes);
  });

  testWidgets('set custom userAgent', (WidgetTester tester) async {
    final PlatformWebViewController controller = PlatformWebViewController(
      const PlatformWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Custom_User_Agent1');

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    final String customUserAgent2 = await _getUserAgent(controller);
    expect(customUserAgent2, 'Custom_User_Agent1');
  });

  group('Video playback policy', () {
    late String videoTestBase64;
    setUpAll(() async {
      final ByteData videoData =
          await rootBundle.load('assets/sample_video.mp4');
      final String base64VideoData =
          base64Encode(Uint8List.view(videoData.buffer));
      final String videoTest = '''
        <!DOCTYPE html><html>
        <head><title>Video auto play</title>
          <script type="text/javascript">
            function play() {
              var video = document.getElementById("video");
              video.play();
              video.addEventListener('timeupdate', videoTimeUpdateHandler, false);
            }
            function videoTimeUpdateHandler(e) {
              var video = document.getElementById("video");
              VideoTestTime.postMessage(video.currentTime);
            }
            function isPaused() {
              var video = document.getElementById("video");
              return video.paused;
            }
            function isFullScreen() {
              var video = document.getElementById("video");
              return video.webkitDisplayingFullscreen;
            }
          </script>
        </head>
        <body onload="play();">
        <video controls playsinline autoplay id="video">
          <source src="data:video/mp4;charset=utf-8;base64,$base64VideoData">
        </video>
        </body>
        </html>
      ''';
      videoTestBase64 = base64Encode(const Utf8Encoder().convert(videoTest));
    });

    testWidgets('Auto media playback', (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$videoTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;

      bool isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, false);

      pageLoaded = Completer<void>();
      controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$videoTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;

      isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, true);
    });

    testWidgets('Video plays inline when allowsInlineMediaPlayback is true',
        (WidgetTester tester) async {
      final Completer<void> pageLoaded = Completer<void>();
      final Completer<void> videoPlaying = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          allowsInlineMediaPlayback: true,
        ),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..addJavaScriptChannel(
          JavaScriptChannelParams(
            name: 'VideoTestTime',
            onMessageReceived: (JavaScriptMessage message) {
              final double currentTime = double.parse(message.message);
              // Let it play for at least 1 second to make sure the related video's properties are set.
              if (currentTime > 1 && !videoPlaying.isCompleted) {
                videoPlaying.complete(null);
              }
            },
          ),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$videoTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));
      await tester.pumpAndSettle();

      await pageLoaded.future;

      // Makes sure we get the correct event that indicates the video is actually playing.
      await videoPlaying.future;

      final bool fullScreen = await controller
          .runJavaScriptReturningResult('isFullScreen();') as bool;
      expect(fullScreen, false);
    });

    testWidgets(
        'Video plays full screen when allowsInlineMediaPlayback is false',
        (WidgetTester tester) async {
      final Completer<void> pageLoaded = Completer<void>();
      final Completer<void> videoPlaying = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..addJavaScriptChannel(
          JavaScriptChannelParams(
            name: 'VideoTestTime',
            onMessageReceived: (JavaScriptMessage message) {
              final double currentTime = double.parse(message.message);
              // Let it play for at least 1 second to make sure the related video's properties are set.
              if (currentTime > 1 && !videoPlaying.isCompleted) {
                videoPlaying.complete(null);
              }
            },
          ),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$videoTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));
      await tester.pumpAndSettle();

      await pageLoaded.future;

      // Makes sure we get the correct event that indicates the video is actually playing.
      await videoPlaying.future;

      final bool fullScreen = await controller
          .runJavaScriptReturningResult('isFullScreen();') as bool;
      expect(fullScreen, true);
    });
  });

  group('Audio playback policy', () {
    late String audioTestBase64;
    setUpAll(() async {
      final ByteData audioData =
          await rootBundle.load('assets/sample_audio.ogg');
      final String base64AudioData =
          base64Encode(Uint8List.view(audioData.buffer));
      final String audioTest = '''
        <!DOCTYPE html><html>
        <head><title>Audio auto play</title>
          <script type="text/javascript">
            function play() {
              var audio = document.getElementById("audio");
              audio.play();
            }
            function isPaused() {
              var audio = document.getElementById("audio");
              return audio.paused;
            }
          </script>
        </head>
        <body onload="play();">
        <audio controls id="audio">
          <source src="data:audio/ogg;charset=utf-8;base64,$base64AudioData">
        </audio>
        </body>
        </html>
      ''';
      audioTestBase64 = base64Encode(const Utf8Encoder().convert(audioTest));
    });

    testWidgets('Auto media playback', (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        ),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$audioTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;

      bool isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, false);

      pageLoaded = Completer<void>();
      controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$audioTestBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;

      isPaused =
          await controller.runJavaScriptReturningResult('isPaused();') as bool;
      expect(isPaused, true);
    });
  });

  testWidgets('getTitle', (WidgetTester tester) async {
    const String getTitleTest = '''
        <!DOCTYPE html><html>
        <head><title>Some title</title>
        </head>
        <body>
        </body>
        </html>
      ''';
    final String getTitleTestBase64 =
        base64Encode(const Utf8Encoder().convert(getTitleTest));
    final Completer<void> pageLoaded = Completer<void>();

    final PlatformWebViewController controller = PlatformWebViewController(
      WebKitWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(
        WebKitNavigationDelegate(
          const WebKitNavigationDelegateCreationParams(),
        )..setOnPageFinished((_) => pageLoaded.complete()),
      )
      ..loadRequest(
        LoadRequestParams(
          uri: Uri.parse(
            'data:text/html;charset=utf-8;base64,$getTitleTestBase64',
          ),
        ),
      );

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageLoaded.future;

    // On at least iOS, it does not appear to be guaranteed that the native
    // code has the title when the page load completes. Execute some JavaScript
    // before checking the title to ensure that the page has been fully parsed
    // and processed.
    await controller.runJavaScript('1;');

    final String? title = await controller.getTitle();
    expect(title, 'Some title');
  });

  group('Programmatic Scroll', () {
    testWidgets('setAndGetScrollPosition', (WidgetTester tester) async {
      const String scrollTestPage = '''
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body {
                height: 100%;
                width: 100%;
              }
              #container{
                width:5000px;
                height:5000px;
            }
            </style>
          </head>
          <body>
            <div id="container"/>
          </body>
        </html>
      ''';

      final String scrollTestPageBase64 =
          base64Encode(const Utf8Encoder().convert(scrollTestPage));

      final Completer<void> pageLoaded = Completer<void>();
      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnPageFinished((_) => pageLoaded.complete()),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,$scrollTestPageBase64',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;

      await tester.pumpAndSettle(const Duration(seconds: 3));

      Offset scrollPos = await controller.getScrollPosition();

      // Check scrollTo()
      const int X_SCROLL = 123;
      const int Y_SCROLL = 321;
      // Get the initial position; this ensures that scrollTo is actually
      // changing something, but also gives the native view's scroll position
      // time to settle.
      expect(scrollPos.dx, isNot(X_SCROLL));
      expect(scrollPos.dy, isNot(Y_SCROLL));

      await controller.scrollTo(X_SCROLL, Y_SCROLL);
      scrollPos = await controller.getScrollPosition();
      expect(scrollPos.dx, X_SCROLL);
      expect(scrollPos.dy, Y_SCROLL);

      // Check scrollBy() (on top of scrollTo())
      await controller.scrollBy(X_SCROLL, Y_SCROLL);
      scrollPos = await controller.getScrollPosition();
      expect(scrollPos.dx, X_SCROLL * 2);
      expect(scrollPos.dy, Y_SCROLL * 2);
    });
  });

  group('NavigationDelegate', () {
    const String blankPage = '<!DOCTYPE html><head></head><body></body></html>';
    final String blankPageEncoded = 'data:text/html;charset=utf-8;base64,'
        '${base64Encode(const Utf8Encoder().convert(blankPage))}';

    testWidgets('can allow requests', (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )
            ..setOnPageFinished((_) => pageLoaded.complete())
            ..setOnNavigationRequest((NavigationRequest navigationRequest) {
              return (navigationRequest.url.contains('youtube.com'))
                  ? NavigationDecision.prevent
                  : NavigationDecision.navigate;
            }),
        )
        ..loadRequest(
          LoadRequestParams(uri: Uri.parse(blankPageEncoded)),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');
      await pageLoaded.future;

      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('onWebResourceError', (WidgetTester tester) async {
      final Completer<WebResourceError> errorCompleter =
          Completer<WebResourceError>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )..setOnWebResourceError((WebResourceError error) {
              errorCompleter.complete(error);
            }),
        )
        ..loadRequest(
          LoadRequestParams(uri: Uri.parse('https://www.notawebsite..com')),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      final WebResourceError error = await errorCompleter.future;
      expect(error, isNotNull);

      expect((error as WebKitWebResourceError).domain, isNotNull);
    });

    testWidgets('onWebResourceError is not called with valid url',
        (WidgetTester tester) async {
      final Completer<WebResourceError> errorCompleter =
          Completer<WebResourceError>();
      final Completer<void> pageFinishCompleter = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )
            ..setOnPageFinished((_) => pageFinishCompleter.complete())
            ..setOnWebResourceError((WebResourceError error) {
              errorCompleter.complete(error);
            }),
        )
        ..loadRequest(
          LoadRequestParams(
            uri: Uri.parse(
              'data:text/html;charset=utf-8;base64,PCFET0NUWVBFIGh0bWw+',
            ),
          ),
        );

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      expect(errorCompleter.future, doesNotComplete);
      await pageFinishCompleter.future;
    });

    testWidgets(
      'onWebResourceError only called for main frame',
      (WidgetTester tester) async {
        const String iframeTest = '''
          <!DOCTYPE html>
          <html>
          <head>
            <title>WebResourceError test</title>
          </head>
          <body>
            <iframe src="https://notawebsite..com"></iframe>
          </body>
          </html>
         ''';
        final String iframeTestBase64 =
            base64Encode(const Utf8Encoder().convert(iframeTest));

        final Completer<WebResourceError> errorCompleter =
            Completer<WebResourceError>();
        final Completer<void> pageFinishCompleter = Completer<void>();

        final PlatformWebViewController controller = PlatformWebViewController(
          WebKitWebViewControllerCreationParams(),
        )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setPlatformNavigationDelegate(
            WebKitNavigationDelegate(
              const WebKitNavigationDelegateCreationParams(),
            )
              ..setOnPageFinished((_) => pageFinishCompleter.complete())
              ..setOnWebResourceError((WebResourceError error) {
                errorCompleter.complete(error);
              }),
          )
          ..loadRequest(
            LoadRequestParams(
              uri: Uri.parse(
                'data:text/html;charset=utf-8;base64,$iframeTestBase64',
              ),
            ),
          );

        await tester.pumpWidget(Builder(
          builder: (BuildContext context) {
            return PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context);
          },
        ));

        expect(errorCompleter.future, doesNotComplete);
        await pageFinishCompleter.future;
      },
    );

    testWidgets('can block requests', (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )
            ..setOnPageFinished((_) => pageLoaded.complete())
            ..setOnNavigationRequest((NavigationRequest navigationRequest) {
              return (navigationRequest.url.contains('youtube.com'))
                  ? NavigationDecision.prevent
                  : NavigationDecision.navigate;
            }),
        )
        ..loadRequest(LoadRequestParams(uri: Uri.parse(blankPageEncoded)));

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller
          .runJavaScript('location.href = "https://www.youtube.com/"');

      // There should never be any second page load, since our new URL is
      // blocked. Still wait for a potential page change for some time in order
      // to give the test a chance to fail.
      await pageLoaded.future
          .timeout(const Duration(milliseconds: 500), onTimeout: () => '');
      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, isNot(contains('youtube.com')));
    });

    testWidgets('supports asynchronous decisions', (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(
          WebKitNavigationDelegate(
            const WebKitNavigationDelegateCreationParams(),
          )
            ..setOnPageFinished((_) => pageLoaded.complete())
            ..setOnNavigationRequest(
                (NavigationRequest navigationRequest) async {
              NavigationDecision decision = NavigationDecision.prevent;
              decision = await Future<NavigationDecision>.delayed(
                  const Duration(milliseconds: 10),
                  () => NavigationDecision.navigate);
              return decision;
            }),
        )
        ..loadRequest(LoadRequestParams(uri: Uri.parse(blankPageEncoded)));

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future; // Wait for initial page load.

      pageLoaded = Completer<void>();
      await controller.runJavaScript('location.href = "$secondaryUrl"');

      await pageLoaded.future; // Wait for second page to load.
      final String? currentUrl = await controller.currentUrl();
      expect(currentUrl, secondaryUrl);
    });

    testWidgets('can receive url changes', (WidgetTester tester) async {
      final Completer<void> pageLoaded = Completer<void>();

      final PlatformNavigationDelegate navigationDelegate =
          PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      )..setOnPageFinished((_) => pageLoaded.complete());

      final PlatformWebViewController controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(navigationDelegate)
        ..loadRequest(LoadRequestParams(uri: Uri.parse(blankPageEncoded)));

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;
      await navigationDelegate.setOnPageFinished((_) {});

      final Completer<String> urlChangeCompleter = Completer<String>();
      await navigationDelegate.setOnUrlChange((UrlChange change) {
        urlChangeCompleter.complete(change.url);
      });

      await controller.runJavaScript('location.href = "$primaryUrl"');

      await expectLater(urlChangeCompleter.future, completion(primaryUrl));
    });

    testWidgets('can receive updates to history state',
        (WidgetTester tester) async {
      final Completer<void> pageLoaded = Completer<void>();

      final PlatformNavigationDelegate navigationDelegate =
          PlatformNavigationDelegate(
        const PlatformNavigationDelegateCreationParams(),
      )..setOnPageFinished((_) => pageLoaded.complete());

      final PlatformWebViewController controller = PlatformWebViewController(
        const PlatformWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(navigationDelegate)
        ..loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      await pageLoaded.future;
      await navigationDelegate.setOnPageFinished((_) {});

      final Completer<String> urlChangeCompleter = Completer<String>();
      await navigationDelegate.setOnUrlChange((UrlChange change) {
        urlChangeCompleter.complete(change.url);
      });

      await controller.runJavaScript(
        'window.history.pushState({}, "", "secondary.txt");',
      );

      await expectLater(urlChangeCompleter.future, completion(secondaryUrl));
    });
  });

  testWidgets('launches with gestureNavigationEnabled on iOS',
      (WidgetTester tester) async {
    final WebKitWebViewController controller = WebKitWebViewController(
      WebKitWebViewControllerCreationParams(),
    )
      ..setAllowsBackForwardNavigationGestures(true)
      ..loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  });

  testWidgets('target _blank opens in same window',
      (WidgetTester tester) async {
    final Completer<void> pageLoaded = Completer<void>();

    final PlatformWebViewController controller = PlatformWebViewController(
      WebKitWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(),
      )..setOnPageFinished((_) => pageLoaded.complete()));

    await controller.runJavaScript('window.open("$primaryUrl", "_blank")');

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        return PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: controller),
        ).build(context);
      },
    ));

    await pageLoaded.future;
    final String? currentUrl = await controller.currentUrl();
    expect(currentUrl, primaryUrl);
  });

  testWidgets(
    'can open new window and go back',
    (WidgetTester tester) async {
      Completer<void> pageLoaded = Completer<void>();

      final PlatformWebViewController controller = PlatformWebViewController(
        WebKitWebViewControllerCreationParams(),
      )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setPlatformNavigationDelegate(WebKitNavigationDelegate(
          const WebKitNavigationDelegateCreationParams(),
        )..setOnPageFinished((_) => pageLoaded.complete()))
        ..loadRequest(LoadRequestParams(uri: Uri.parse(primaryUrl)));

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          return PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(controller: controller),
          ).build(context);
        },
      ));

      expect(controller.currentUrl(), completion(primaryUrl));
      await pageLoaded.future;
      pageLoaded = Completer<void>();

      await controller.runJavaScript('window.open("$secondaryUrl")');
      await pageLoaded.future;
      pageLoaded = Completer<void>();
      expect(controller.currentUrl(), completion(secondaryUrl));

      expect(controller.canGoBack(), completion(true));
      await controller.goBack();
      await pageLoaded.future;
      await expectLater(controller.currentUrl(), completion(primaryUrl));
    },
  );
}

/// Returns the value used for the HTTP User-Agent: request header in subsequent HTTP requests.
Future<String> _getUserAgent(PlatformWebViewController controller) async {
  return await controller.runJavaScriptReturningResult('navigator.userAgent;')
      as String;
}

class ResizableWebView extends StatefulWidget {
  const ResizableWebView({
    super.key,
    required this.onResize,
    required this.onPageFinished,
  });

  final VoidCallback onResize;
  final VoidCallback onPageFinished;

  @override
  State<StatefulWidget> createState() => ResizableWebViewState();
}

class ResizableWebViewState extends State<ResizableWebView> {
  late final PlatformWebViewController controller = PlatformWebViewController(
    const PlatformWebViewControllerCreationParams(),
  )
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setPlatformNavigationDelegate(
      WebKitNavigationDelegate(
        const WebKitNavigationDelegateCreationParams(),
      )..setOnPageFinished((_) => widget.onPageFinished()),
    )
    ..addJavaScriptChannel(
      JavaScriptChannelParams(
        name: 'Resize',
        onMessageReceived: (_) {
          widget.onResize();
        },
      ),
    )
    ..loadRequest(
      LoadRequestParams(
        uri: Uri.parse(
          'data:text/html;charset=utf-8;base64,${base64Encode(const Utf8Encoder().convert(resizePage))}',
        ),
      ),
    );

  double webViewWidth = 200;
  double webViewHeight = 200;

  static const String resizePage = '''
        <!DOCTYPE html><html>
        <head><title>Resize test</title>
          <script type="text/javascript">
            function onResize() {
              Resize.postMessage("resize");
            }
            function onLoad() {
              window.onresize = onResize;
            }
          </script>
        </head>
        <body onload="onLoad();" bgColor="blue">
        </body>
        </html>
      ''';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          SizedBox(
            width: webViewWidth,
            height: webViewHeight,
            child: PlatformWebViewWidget(
              PlatformWebViewWidgetCreationParams(controller: controller),
            ).build(context),
          ),
          TextButton(
            key: const Key('resizeButton'),
            onPressed: () {
              setState(() {
                webViewWidth += 100.0;
                webViewHeight += 100.0;
              });
            },
            child: const Text('ResizeButton'),
          ),
        ],
      ),
    );
  }
}

class CopyableObjectWithCallback with Copyable {
  CopyableObjectWithCallback(this.callback);

  final VoidCallback callback;

  @override
  CopyableObjectWithCallback copy() {
    return CopyableObjectWithCallback(callback);
  }
}

class ClassWithCallbackClass {
  ClassWithCallbackClass() {
    callbackClass = CopyableObjectWithCallback(
      withWeakReferenceTo(
        this,
        (WeakReference<ClassWithCallbackClass> weakReference) {
          return () {
            // Weak reference to `this` in callback.
            // ignore: unnecessary_statements
            weakReference;
          };
        },
      ),
    );
  }

  late final CopyableObjectWithCallback callbackClass;
}
