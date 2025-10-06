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
  FakeWidgetPreviewScaffoldDtdServices({this.isWindows = false});

  final navigationEvents = <CodeLocation>[];
  final preferences = <String, Object?>{};

  @override
  Future<void> connect({Uri? dtdUri}) async {}

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  bool hotRestartInvoked = false;

  @override
  Future<void> hotRestartPreviewer() async {
    hotRestartInvoked = true;
  }

  /// Resolves a package:// URI to a file:// URI using the package_config.
  ///
  /// Returns null if [uri] can not be resolved.
  @override
  Future<Uri?> resolveUri(Uri uri) async {
    return uri;
  }

  @override
  final bool isWindows;

  /// The currently selected source file in the IDE.
  @override
  final ValueNotifier<TextDocument?> selectedSourceFile =
      ValueNotifier<TextDocument?>(null);

  /// Whether or not the Editor service is available.
  @override
  final ValueNotifier<bool> editorServiceAvailable = ValueNotifier<bool>(true);

  /// Tells the editor to navigate to a given code [location].
  ///
  /// Only locations with `file://` URIs are valid.
  @override
  Future<void> navigateToCode(CodeLocation location) async {
    navigationEvents.add(location);
  }

  /// Retrieves the state of flag [key] from the persistent preferences map.
  ///
  /// If [key] is not set, [defaultValue] is returned.
  @override
  Future<bool> getFlag(String flag, {bool defaultValue = true}) async {
    return preferences[flag] as bool? ?? defaultValue;
  }

  /// Sets [key] to [value] in the persistent preferences map.
  @override
  Future<void> setPreference(String key, Object? value) async {
    if (value == null) {
      preferences.remove(key);
      return;
    }
    preferences[key] = value;
  }
}

class FakeWidgetPreviewScaffoldController
    extends WidgetPreviewScaffoldController {
  FakeWidgetPreviewScaffoldController({
    WidgetPreviewScaffoldDtdServices? dtdServicesOverride,
    List<WidgetPreview>? previews,
  }) : super(
         previews: () => previews ?? [],
         dtdServicesOverride:
             dtdServicesOverride ?? FakeWidgetPreviewScaffoldDtdServices(),
       );
}
