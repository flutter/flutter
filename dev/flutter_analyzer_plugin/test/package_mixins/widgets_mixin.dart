// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

extension FlutterWidgetsPackageConfigExtnesion on PackageConfigFileBuilder {
  PackageConfigFileBuilder addFlutterWidgetsPackage(AnalysisRuleTest test) {
    add(
      name: FlutterWidgetsPackage._flutterPackageName,
      rootPath: test.convertPath(FlutterWidgetsPackage._flutterPackageRoot),
    );
    return this;
  }
}

/// Mixin application that allows for `package:flutter/widgets.dart` imports in tests.
mixin FlutterWidgetsPackage on AnalysisRuleTest {
  static const String _flutterPackageName = 'flutter';
  static const String _flutterPackageRoot = '/packages/$_flutterPackageName';

  @override
  void setUp() {
    super.setUp();
    newFile('$_flutterPackageRoot/lib/widgets.dart', '''
library widgets;

abstract class StatefulWidget {
  const StatefulWidget();

  @protected
  @factory
  State createState();
}

mixin Diagnosticable {
  @protected
  @mustCallSuper
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

class DiagnosticPropertiesBuilder {}
class BuildContext {}
class Widget {}

typedef VoidCallback = void Function();

@optionalTypeArgs
abstract class State<T extends StatefulWidget> with Diagnosticable {
  @protected
  @mustCallSuper
  void initState() {}

  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}

  @protected
  @mustCallSuper
  void reassemble() {}

  @protected
  void setState(VoidCallback fn) {}

  @protected
  @mustCallSuper
  void deactivate() {}

  @protected
  @mustCallSuper
  void activate() {}

  @protected
  @mustCallSuper
  void dispose() {}

  @protected
  Widget build(BuildContext context);

  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }

  // If @protected State methods are added or removed, the analysis rule should be
  // updated accordingly (dev/bots/custom_rules/protect_public_state_subtypes.dart)
}
''');
  }
}
