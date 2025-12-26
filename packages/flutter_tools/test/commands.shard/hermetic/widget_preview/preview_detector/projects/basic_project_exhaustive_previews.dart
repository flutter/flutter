// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../../utils/preview_details_matcher.dart';
import '../../utils/preview_project.dart';

/// Creates a project with files containing previews that attempt to use as many widget preview
/// properties as possible.
class BasicProjectWithExhaustivePreviews extends WidgetPreviewProject with ProjectWithPreviews {
  BasicProjectWithExhaustivePreviews._({
    required super.projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    initialize(pathsWithPreviews: pathsWithPreviews, pathsWithoutPreviews: pathsWithoutPreviews);
  }

  static Future<BasicProjectWithExhaustivePreviews> create({
    required Directory projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) async {
    final project = BasicProjectWithExhaustivePreviews._(
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
    throw UnimplementedError('Not supported for $BasicProjectWithExhaustivePreviews');
  }

  @override
  late final expectedPreviewDetails = <PreviewDetailsMatcher>[
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'previews',
      isBuilder: false,
      name: 'Top-level preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'builderPreview',
      isBuilder: true,
      name: 'Builder preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'attributesPreview',
      isBuilder: false,
      name: 'Attributes preview',
      // This is DartObject's toString() representation for the constant evaluation of a Size.
      size: 'Size ((super) = OffsetBase (_dx = double (100.0); _dy = double (100.0)))',
      textScaleFactor: 2.0,
      wrapper: 'testWrapper',
      theme: 'theming',
      // This is DartObject's toString() representation for an enum value.
      brightness: 'Brightness dark',
      localizations: 'localizations',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.preview',
      isBuilder: false,
      name: 'Constructor preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.factoryPreview',
      isBuilder: false,
      name: 'Factory constructor preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.previewStatic',
      isBuilder: false,
      name: 'Static preview',
    ),
  ];

  @override
  final previewContainingFileContents = '''
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@Preview(name: 'Top-level preview')
Widget previews() => Text('Foo');

@Preview(name: 'Builder preview')
WidgetBuilder builderPreview() {
  return (BuildContext context) {
    return Text('Builder');
  };
}

Widget testWrapper(Widget child) {
  return child;
}

PreviewThemeData theming() => PreviewThemeData(
  materialLight: ThemeData(colorScheme: ColorScheme.light(primary: Colors.red)),
  materialDark: ThemeData(colorScheme: ColorScheme.dark(primary: Colors.blue)),
  cupertinoLight: CupertinoThemeData(primaryColor: Colors.yellow),
  cupertinoDark: CupertinoThemeData(primaryColor: Colors.purple),
);

PreviewLocalizationsData localizations() {
  return PreviewLocalizationsData(
    locale: Locale('en'),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('en'), // English
      Locale('es'), // Spanish
    ],
    localeListResolutionCallback:
        (List<Locale>? locales, Iterable<Locale> supportedLocales) => null,
    localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) => null,
  );
}

const String kAttributesPreview = 'Attributes preview';
@Preview(
  name: kAttributesPreview,
  size: Size(100.0, 100),
  textScaleFactor: 2.0,
  wrapper: testWrapper,
  theme: theming,
  brightness: Brightness.dark,
  localizations: localizations,
)
Widget attributesPreview() {
  return Text('Attributes');
}

class MyWidget extends StatelessWidget {
  @Preview(name: 'Constructor preview')
  MyWidget.preview();

  @Preview(name: 'Factory constructor preview')
  factory MyWidget.factoryPreview() => MyWidget.preview();

  @Preview(name: 'Static preview')
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
