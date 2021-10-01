// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' as vector_math_64;
import 'package:args/args.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:fidl_fuchsia_ui_app/fidl_async.dart';
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

// TODO(richkadel): To run the test serving the runner and test packages from
// the flutter/engine package server (via
// `//flutter/tools/fuchsia/devshell/serve.sh`), change `fuchsia.com` to
// `engine`.
const _kChildAppUrl =
    'fuchsia-pkg://fuchsia.com/child-view2#meta/child-view2.cmx';

TestApp app;

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('showOverlay', defaultsTo: false)
    ..addFlag('hitTestable', defaultsTo: true)
    ..addFlag('focusable', defaultsTo: true);
  final arguments = parser.parse(args);
  for (final option in arguments.options) {
    print('parent-view2: $option: ${arguments[option]}');
  }

  final childViewToken = _launchApp(_kChildAppUrl);

  app = TestApp(
    ChildView(childViewToken),
    showOverlay: arguments['showOverlay'],
    hitTestable: arguments['hitTestable'],
    focusable: arguments['focusable'],
  );

  app.run();
}

class TestApp {
  static const _black = Color.fromARGB(255, 0, 0, 0);
  static const _blue = Color.fromARGB(255, 0, 0, 255);

  final ChildView childView;
  final bool showOverlay;
  final bool hitTestable;
  final bool focusable;

  Color _backgroundColor = _blue;

  TestApp(
    this.childView,
    {this.showOverlay = false,
    this.hitTestable = true,
    this.focusable = true}) {
  }

  void run() {
    childView.create(hitTestable, focusable, (ByteData reply) {
        // The child-view2 should be attached to Scenic now.
        // Ready to build the scene.
        window.onPointerDataPacket = (PointerDataPacket packet) {
          for (final data in packet.data) {
            if (data.change == PointerChange.up) {
              this._backgroundColor = _black;
            }
          }
          window.scheduleFrame();
        };
        window.onBeginFrame = (Duration duration) {
          app.beginFrame(duration);
        };
        window.scheduleFrame();
      });
  }

  void beginFrame(Duration duration) {
    final windowPhysicalBounds = Offset.zero & window.physicalSize;
    final pixelRatio = window.devicePixelRatio;
    final windowSize = window.physicalSize / pixelRatio;
    final windowBounds = Offset.zero & windowSize;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, windowPhysicalBounds);
    canvas.scale(pixelRatio);
    final paint = Paint()..color = this._backgroundColor;
    canvas.drawRect(windowBounds, paint);
    final picture = recorder.endRecording();

    final sceneBuilder = SceneBuilder()
      ..pushClipRect(windowPhysicalBounds)
      ..addPicture(Offset.zero, picture);

    final childPhysicalSize = window.physicalSize * 0.33;
    // Alignment.center
    final windowCenter = windowSize.center(Offset.zero);
    final windowPhysicalCenter = window.physicalSize.center(Offset.zero);
    final childPhysicalOffset = windowPhysicalCenter - childPhysicalSize.center(Offset.zero);

    sceneBuilder
      ..pushTransform(
        vector_math_64.Matrix4.translationValues(childPhysicalOffset.dx,
                                                 childPhysicalOffset.dy,
                                                 0.0).storage)
      ..addPlatformView(childView.viewId,
                        width: childPhysicalSize.width,
                        height: childPhysicalSize.height)
      ..pop()
    ;

    if (showOverlay) {
      final containerSize = windowSize * .66;
      // Alignment.center
      final containerOffset = windowCenter - containerSize.center(Offset.zero);

      final overlaySize = containerSize * 0.5;
      // Alignment.topRight
      final overlayOffset = Offset(
        containerOffset.dx + containerSize.width - overlaySize.width,
        containerOffset.dy);

      final overlayPhysicalSize = overlaySize * pixelRatio;
      final overlayPhysicalOffset = overlayOffset * pixelRatio;
      final overlayPhysicalBounds = overlayPhysicalOffset & overlayPhysicalSize;

      final recorder = PictureRecorder();
      final overlayCullRect = Offset.zero & overlayPhysicalSize; // in canvas physical coordinates
      final canvas = Canvas(recorder, overlayCullRect);
      canvas.scale(pixelRatio);
      final paint = Paint()..color = Color.fromARGB(255, 0, 255, 0);
      canvas.drawRect(Offset.zero & overlaySize, paint);
      final overlayPicture = recorder.endRecording();
      sceneBuilder
        ..pushClipRect(overlayPhysicalBounds) // in window physical coordinates
        ..addPicture(overlayPhysicalOffset, overlayPicture)
        ..pop()
        ;
    }
    sceneBuilder.pop();

    window.render(sceneBuilder.build());
  }
}

ViewHolderToken _launchApp(String componentUrl) {
  final incoming = Incoming();
  final componentController = ComponentControllerProxy();

  final launcher = LauncherProxy();
  Incoming.fromSvcPath()
    ..connectToService(launcher)
    ..close();
  launcher.createComponent(
    LaunchInfo(
      url: componentUrl,
      directoryRequest: incoming.request().passChannel(),
    ),
    componentController.ctrl.request(),
  );
  launcher.ctrl.close();

  ViewProviderProxy viewProvider = ViewProviderProxy();
  incoming
    ..connectToService(viewProvider)
    ..close();

  final viewTokens = EventPairPair();
  assert(viewTokens.status == ZX.OK);
  final viewHolderToken = ViewHolderToken(value: viewTokens.first);
  final viewToken = ViewToken(value: viewTokens.second);

  viewProvider.createView(viewToken.value, null, null);
  viewProvider.ctrl.close();

  return viewHolderToken;
}

class ChildView {

  final ViewHolderToken viewToken;
  final int viewId;

  ChildView(this.viewToken) : viewId = viewToken.value.handle.handle {
    assert(viewId != null);
  }

  void create(
    bool hitTestable,
    bool focusable,
    PlatformMessageResponseCallback callback) {
    // Construct the dart:ui platform message to create the view, and when the
    // return callback is invoked, build the scene. At that point, it is safe
    // to embed the child-view2 in the scene.
    final viewOcclusionHint = Rect.zero;

    final Map<String, dynamic> args = <String, dynamic>{
      'viewId': viewId,
      'hitTestable': hitTestable,
      'focusable': focusable,
      'viewOcclusionHintLTRB': <double>[
        viewOcclusionHint.left,
        viewOcclusionHint.top,
        viewOcclusionHint.right,
        viewOcclusionHint.bottom
      ],
    };

    final ByteData createViewMessage = utf8.encoder.convert(
      json.encode(<String, Object>{
        'method': 'View.create',
        'args': args,
      })
    ).buffer.asByteData();

    final platformViewsChannel = 'flutter/platform_views';

    PlatformDispatcher.instance.sendPlatformMessage(
      platformViewsChannel,
      createViewMessage,
      callback);
  }
}
