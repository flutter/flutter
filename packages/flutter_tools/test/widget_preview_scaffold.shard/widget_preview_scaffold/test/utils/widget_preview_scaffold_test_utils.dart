// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/dtd/dtd_services.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'package:widget_preview_scaffold/src/widget_preview_scaffold_controller.dart';

class WidgetPreviewerWidgetScaffolding extends StatelessWidget {
  WidgetPreviewerWidgetScaffolding({
    super.key,
    this.platformBrightness = Brightness.light,
    required this.child,
  }) {
    // This is set unconditionally by the preview scaffolding.
    WidgetsBinding.instance.debugExcludeRootWidgetInspector = true;
  }

  /// Sets the root platform brightness. Defaults to light.
  final Brightness platformBrightness;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(platformBrightness: platformBrightness),
      child: WidgetsApp(
        color: Colors.blue,
        home: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return WidgetPreviewerWindowConstraints(
              constraints: constraints,
              child: child,
            );
          },
        ),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
            ),
      ),
    );
  }
}

class FakeWidgetPreviewScaffoldDtdServices extends Fake
    with DtdEditorService
    implements WidgetPreviewScaffoldDtdServices {
  @override
  Future<void> connect({Uri? dtdUri}) async {}

  @override
  Future<void> dispose() async {}

  bool hotRestartInvoked = false;

  @override
  Future<void> hotRestartPreviewer() async {
    hotRestartInvoked = true;
  }

  /// The currently selected source file in the IDE.
  @override
  final ValueNotifier<TextDocument?> selectedSourceFile =
      ValueNotifier<TextDocument?>(null);
}

class FakeWidgetPreviewScaffoldController
    extends WidgetPreviewScaffoldController {
  FakeWidgetPreviewScaffoldController({
    WidgetPreviewScaffoldDtdServices? dtdServices,
    List<WidgetPreview>? previews,
  }) : dtdServices = dtdServices ?? FakeWidgetPreviewScaffoldDtdServices(),
       super(previews: () => previews ?? []);

  @override
  final WidgetPreviewScaffoldDtdServices dtdServices;
}
