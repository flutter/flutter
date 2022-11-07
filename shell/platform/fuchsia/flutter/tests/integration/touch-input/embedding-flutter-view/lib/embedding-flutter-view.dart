// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';

import 'package:fidl_fuchsia_ui_app/fidl_async.dart';
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:fidl_fuchsia_ui_test_input/fidl_async.dart' as test_touch;
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

void main(List<String> args) {
  print('Launching embedding-flutter-view');
  TestApp app = TestApp(ChildView.gfx(_launchGfxChildView()));
  app.run();
}

class TestApp {
  static const _black = Color.fromARGB(255, 0, 0, 0);
  static const _blue = Color.fromARGB(255, 0, 0, 255);

  final ChildView childView;
  final _responseListener = test_touch.TouchInputListenerProxy();

  Color _backgroundColor = _blue;

  TestApp(this.childView) {}

  void run() {
    childView.create((ByteData reply) {
        // Set up window callbacks.
        window.onPointerDataPacket = (PointerDataPacket packet) {
          this.pointerDataPacket(packet);
        };
        window.onMetricsChanged = () {
          window.scheduleFrame();
        };
        window.onBeginFrame = (Duration duration) {
          this.beginFrame(duration);
        };

        // The child view should be attached to Scenic now.
        // Ready to build the scene.
        window.scheduleFrame();
      });
  }

  void beginFrame(Duration duration) {
    // Convert physical screen size of device to values
    final pixelRatio = window.devicePixelRatio;
    final size = window.physicalSize / pixelRatio;
    final physicalBounds = Offset.zero & window.physicalSize;
    final windowBounds = Offset.zero & size;
    // Set up a Canvas that uses the screen size
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, physicalBounds);
    canvas.scale(pixelRatio);
    // Draw something
    final paint = Paint()..color = this._backgroundColor;
    canvas.drawRect(windowBounds, paint);
    final picture = recorder.endRecording();
    // Build the scene
    final sceneBuilder = SceneBuilder()
      ..pushClipRect(physicalBounds)
      ..addPicture(Offset.zero, picture);
    // Child view should take up half the screen
    final childPhysicalSize = window.physicalSize * 0.5;
    sceneBuilder
      ..addPlatformView(childView.viewId,
                        width: childPhysicalSize.width,
                        height: size.height)
      ..pop();
    sceneBuilder.pop();
    window.render(sceneBuilder.build());
  }

  void pointerDataPacket(PointerDataPacket packet) async {
    int nowNanos = System.clockGetMonotonic();

    for (PointerData data in packet.data) {
      print('embedding-flutter-view received tap: ${data.toStringFull()}');

      if (data.change == PointerChange.down) {
        this._backgroundColor = _black;
      }

      if (data.change == PointerChange.down || data.change == PointerChange.move) {
        Incoming.fromSvcPath()
          ..connectToService(_responseListener)
          ..close();

        _respond(test_touch.TouchInputListenerReportTouchInputRequest(
          localX: data.physicalX,
          localY: data.physicalY,
          timeReceived: nowNanos,
          componentName: 'embedding-flutter-view',
        ));
      }
    }

    window.scheduleFrame();
  }

  void _respond(test_touch.TouchInputListenerReportTouchInputRequest request) async {
    print('embedding-flutter-view reporting touch input to TouchInputListener');
    await _responseListener.reportTouchInput(request);
  }
}

class ChildView {
  final ViewHolderToken viewHolderToken;
  final ViewportCreationToken viewportCreationToken;
  final int viewId;

  ChildView(this.viewportCreationToken) : viewHolderToken = null, viewId = viewportCreationToken.value.handle.handle {
    assert(viewId != null);
  }

  ChildView.gfx(this.viewHolderToken) : viewportCreationToken = null, viewId = viewHolderToken.value.handle.handle {
    assert(viewId != null);
  }

  void create(PlatformMessageResponseCallback callback) {
    // Construct the dart:ui platform message to create the view, and when the
    // return callback is invoked, build the scene. At that point, it is safe
    // to embed the child view in the scene.
    final viewOcclusionHint = Rect.zero;
    final Map<String, dynamic> args = <String, dynamic>{
      'viewId': viewId,
      'hitTestable': true,
      'focusable': true,
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

ViewHolderToken _launchGfxChildView() {
  ViewProviderProxy viewProvider = ViewProviderProxy();
  Incoming.fromSvcPath()
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
