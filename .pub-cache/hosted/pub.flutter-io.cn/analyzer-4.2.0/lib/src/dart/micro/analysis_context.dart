// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/uri_converter.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

MicroContextObjects createMicroContextObjects({
  required FileResolver fileResolver,
  required AnalysisOptionsImpl analysisOptions,
  required SourceFactory sourceFactory,
  required ContextRootImpl root,
  required ResourceProvider resourceProvider,
}) {
  var declaredVariables = DeclaredVariables();

  var analysisSession = _MicroAnalysisSessionImpl(
    fileResolver,
    declaredVariables,
    sourceFactory,
  );

  var analysisContext2 = _MicroAnalysisContextImpl(
    fileResolver,
    analysisOptions,
    root,
    declaredVariables,
    sourceFactory,
    resourceProvider,
  );

  analysisContext2.currentSession = analysisSession;
  analysisSession.analysisContext = analysisContext2;

  return MicroContextObjects._(
    declaredVariables: declaredVariables,
    analysisOptions: analysisOptions,
    analysisSession: analysisSession,
  );
}

class MicroContextObjects {
  final DeclaredVariables declaredVariables;
  final AnalysisOptionsImpl analysisOptions;
  final _MicroAnalysisSessionImpl analysisSession;

  MicroContextObjects._({
    required this.declaredVariables,
    required this.analysisOptions,
    required this.analysisSession,
  });

  InheritanceManager3 get inheritanceManager {
    return analysisSession.inheritanceManager;
  }
}

class _FakeAnalysisDriver implements AnalysisDriver {
  final FileResolver fileResolver;

  late _MicroAnalysisSessionImpl _currentSession;

  _FakeAnalysisDriver(this.fileResolver);

  @override
  AnalysisSessionImpl get currentSession {
    _currentSession = fileResolver.contextObjects?.analysisSession
        as _MicroAnalysisSessionImpl;
    return _currentSession;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MicroAnalysisContextImpl implements AnalysisContext {
  final FileResolver fileResolver;

  @override
  AnalysisOptionsImpl analysisOptions;

  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  @override
  late _MicroAnalysisSessionImpl currentSession;

  final DeclaredVariables declaredVariables;

  final SourceFactory sourceFactory;

  _MicroAnalysisContextImpl(
    this.fileResolver,
    this.analysisOptions,
    this.contextRoot,
    this.declaredVariables,
    this.sourceFactory,
    this.resourceProvider,
  );

  @override
  Folder? get sdkRoot => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MicroAnalysisSessionImpl extends AnalysisSessionImpl {
  final FileResolver fileResolver;

  @override
  final DeclaredVariables declaredVariables;

  final SourceFactory sourceFactory;

  @override
  late _MicroAnalysisContextImpl analysisContext;

  @override
  late final LinkedElementFactory elementFactory;

  _MicroAnalysisSessionImpl(
    this.fileResolver,
    this.declaredVariables,
    this.sourceFactory,
  ) : super(_FakeAnalysisDriver(fileResolver));

  @override
  ResourceProvider get resourceProvider =>
      analysisContext.contextRoot.resourceProvider;

  @override
  UriConverter get uriConverter {
    return _UriConverterImpl(
      analysisContext.contextRoot.resourceProvider,
      sourceFactory,
    );
  }

  @override
  Future<SomeLibraryElementResult> getLibraryByUri(String uriStr) async {
    var element = await analysisContext.fileResolver.getLibraryByUri2(
      uriStr: uriStr,
    );
    return LibraryElementResultImpl(element);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path) async {
    return analysisContext.fileResolver.resolveLibrary2(path: path);
  }

  @override
  Future<SomeResolvedUnitResult> getResolvedUnit(String path) async {
    return analysisContext.fileResolver.resolve2(path: path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UriConverterImpl implements UriConverter {
  final ResourceProvider resourceProvider;
  final SourceFactory sourceFactory;

  _UriConverterImpl(this.resourceProvider, this.sourceFactory);

  @override
  Uri? pathToUri(String path, {String? containingPath}) {
    return sourceFactory.pathToUri(path);
  }

  @override
  String? uriToPath(Uri uri) {
    return sourceFactory.forUri2(uri)?.fullName;
  }
}
