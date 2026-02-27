// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:test/test.dart';

import '../../utils/preview_details_matcher.dart';
import '../../utils/preview_project.dart';

/// Creates a project with files containing a custom MultiPreview instance used to apply light and
/// dark mode previews to individual functions.
class MultiPreviewProject extends WidgetPreviewProject with ProjectWithPreviews {
  MultiPreviewProject._({
    required super.projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    initialize(pathsWithPreviews: pathsWithPreviews, pathsWithoutPreviews: pathsWithoutPreviews);
  }
  static Future<MultiPreviewProject> create({
    required Directory projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) async {
    final project = MultiPreviewProject._(
      projectRoot: projectRoot,
      pathsWithPreviews: pathsWithPreviews,
      pathsWithoutPreviews: pathsWithoutPreviews,
    );
    await project.initializePubspec();
    return project;
  }

  @override
  // ignore: must_call_super, always throws
  void removeDirectoryContaining(WidgetPreviewSourceFile file) {
    throw UnimplementedError('Not supported for $MultiPreviewProject');
  }

  static final previewMatchers = <PreviewMatcher>[
    PreviewMatcher(
      name: 'Light',
      // This is DartObject's toString() representation for an enum value.
      brightness: 'Brightness light',
    ),
    PreviewMatcher(
      name: 'Dark',
      // This is DartObject's toString() representation for an enum value.
      brightness: 'Brightness dark',
    ),
  ];

  @override
  late final expectedPreviewDetails = <Matcher>[
    MultiPreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'previews',
      isBuilder: false,
      previewMatchers: previewMatchers,
    ),
    MultiPreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'builderPreview',
      isBuilder: true,
      previewMatchers: previewMatchers,
    ),
    MultiPreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.preview',
      isBuilder: false,
      previewMatchers: previewMatchers,
    ),
    MultiPreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.factoryPreview',
      isBuilder: false,
      previewMatchers: previewMatchers,
    ),
    MultiPreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.previewStatic',
      isBuilder: false,
      previewMatchers: previewMatchers,
    ),
  ];

  @override
  final previewContainingFileContents = '''
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

base class BrightnessPreview extends MultiPreview {
  const BrightnessPreview();

  @override
  final List<Preview> previews = <Preview>[
    Preview(name: 'Light', brightness: Brightness.light),
    Preview(name: 'Dark', brightness: Brightness.dark),
  ];
}

@BrightnessPreview()
Widget previews() => Text('Foo');

@BrightnessPreview()
WidgetBuilder builderPreview() {
  return (BuildContext context) {
    return Text('Builder');
  };
}

class MyWidget extends StatelessWidget {
  @BrightnessPreview()
  MyWidget.preview();

  @BrightnessPreview()
  factory MyWidget.factoryPreview() => MyWidget.preview();

  @BrightnessPreview()
  static Widget previewStatic() => Text('Static');

  @override
  Widget build(BuildContext context) {
    return Text('MyWidget');
  }
}
''';

  @override
  final nonPreviewContainingFileContents = '''
String foo() => 'bar';
''';
}
