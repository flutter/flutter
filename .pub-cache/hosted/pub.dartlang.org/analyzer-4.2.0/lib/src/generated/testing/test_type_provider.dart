// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';

/// A type provider that can be used by tests without creating the element model
/// for the core library.
class TestTypeProvider extends TypeProviderImpl {
  factory TestTypeProvider() {
    var analysisContext = _MockAnalysisContext();
    var analysisSession = _MockAnalysisSession();
    var sdkElements = MockSdkElements(analysisContext, analysisSession);
    return TestTypeProvider._(
      sdkElements.coreLibrary,
      sdkElements.asyncLibrary,
    );
  }

  TestTypeProvider._(
    LibraryElement coreLibrary,
    LibraryElement asyncLibrary,
  ) : super(
          coreLibrary: coreLibrary,
          asyncLibrary: asyncLibrary,
          isNonNullableByDefault: true,
        );
}

class _MockAnalysisContext implements AnalysisContext {
  @override
  final SourceFactory sourceFactory = _MockSourceFactory();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAnalysisSession implements AnalysisSessionImpl {
  @override
  final ClassHierarchy classHierarchy = ClassHierarchy();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  String get fullName => uri.path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSourceFactory implements SourceFactory {
  @override
  Source forUri(String uriStr) {
    var uri = Uri.parse(uriStr);
    return _MockSource(uri);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
