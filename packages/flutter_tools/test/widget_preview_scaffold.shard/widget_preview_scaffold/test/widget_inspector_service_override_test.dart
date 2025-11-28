// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_preview_scaffold/src/widget_preview_inspector_service.dart';

import 'utils/widget_preview_scaffold_test_utils.dart';

void main() {
  test(
    'Ensure $WidgetPreviewScaffoldInspectorService is initialized correctly',
    () async {
      expect(
        WidgetInspectorService.instance,
        isNot(isA<WidgetPreviewScaffoldInspectorService>()),
      );
      final dtdServices = FakeWidgetPreviewScaffoldDtdServices();
      // Override the original WidgetInspectorService with our custom version.
      TestWidgetPreviewScaffoldInspectorService(dtdServices: dtdServices);
      expect(
        WidgetInspectorService.instance,
        isA<WidgetPreviewScaffoldInspectorService>(),
      );
      // Initialize the bindings and verify that the inspector service hasn't been
      // changed and that initServiceExtensions has been invoked. This indicates
      // that the inspector service extensions have been initialized with the custom
      // inspector service instance and will be routed through the overridden methods.
      WidgetsFlutterBinding.ensureInitialized();
      expect(
        WidgetInspectorService.instance,
        isA<WidgetPreviewScaffoldInspectorService>(),
      );
      expect(
        TestWidgetPreviewScaffoldInspectorService.serviceExtensionsRegistered,
        true,
      );
    },
  );
}

final class TestWidgetPreviewScaffoldInspectorService
    extends WidgetPreviewScaffoldInspectorService {
  TestWidgetPreviewScaffoldInspectorService({required super.dtdServices});

  static bool serviceExtensionsRegistered = false;

  @override
  void initServiceExtensions(
    RegisterServiceExtensionCallback registerExtension,
  ) {
    super.initServiceExtensions(registerExtension);
    serviceExtensionsRegistered = true;
  }
}
