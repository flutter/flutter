// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final boundaryKey = GlobalKey();
final scrollController = ScrollController();
void main() {
  runApp(RepaintBoundary(key: boundaryKey, child: const GradientScene()));
  final output = Platform.environment['GRADIENT_PROBE_OUTPUT'];
  if (output != null) {
    final physical = Platform.environment['GRADIENT_PROBE_PHYSICAL'] == '1';
    final limit = physical ? 60 : 12;
    var busy = false;
    var index = 0;
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (busy || index >= limit) {
        if (index >= limit) timer.cancel();
        return;
      }
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return;
      busy = true;
      try {
        final view = View.of(boundaryKey.currentContext!);
        final image = await boundary.toImage(pixelRatio: physical ? view.devicePixelRatio : 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (bytes != null) {
          final path = '$output/frame-$index.rgba';
          await File(path)
              .writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
          final meta = File('$output/latest.tmp');
          await meta.writeAsString(
            jsonEncode({
              'dpr': view.devicePixelRatio,
              'display_id': view.display.id,
              'display_dpr': view.display.devicePixelRatio,
              'display_width': view.display.size.width,
              'display_height': view.display.size.height,
              'physical_width': view.physicalSize.width,
              'physical_height': view.physicalSize.height,
              'width': image.width,
              'height': image.height,
              'path': path,
              'index': index,
              'scroll_offset': scrollController.offset,
            }),
          );
          await meta.rename('$output/latest.json');
          index++;
          if (index == 1) scrollController.jumpTo(40);
        }
        image.dispose();
      } finally {
        busy = false;
      }
    });
  }
}

class GradientScene extends StatelessWidget {
  const GradientScene({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: ui.TextDirection.ltr,
    child: ColoredBox(
      color: const Color(0xff202020),
      child: SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: 900,
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 20,
                width: 600,
                height: 200,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffff0000), Color(0xff0000ff)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 250,
                width: 1100,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x8000ff00), Color(0xff0000ff)],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                top: 440,
                width: 600,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 2.5,
                      colors: [Color(0xffff0000), Color(0xff0000ff)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 700,
                top: 20,
                width: 400,
                height: 200,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xffff0000), Color(0xff0000ff)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
