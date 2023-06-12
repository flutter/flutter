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
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/workspace/workspace.dart';

MicroContextObjects createMicroContextObjects({
  required FileResolver fileResolver,
  required AnalysisOptionsImpl analysisOptions,
  required SourceFactory sourceFactory,
  required ContextRootImpl root,
  required ResourceProvider resourceProvider,
}) {
  var declaredVariables = DeclaredVariables();
  var synchronousSession = SynchronousSession(
    analysisOptions,
    declaredVariables,
  );

  var analysisContext = AnalysisContextImpl(
    synchronousSession,
    sourceFactory,
  );

  var analysisSession = _MicroAnalysisSessionImpl(
    fileResolver,
    declaredVariables,
    sourceFactory,
  );

  var analysisContext2 = _MicroAnalysisContextImpl(
    fileResolver,
    synchronousSession,
    root,
    declaredVariables,
    sourceFactory,
    resourceProvider,
  );

  analysisContext2.currentSession = analysisSession;
  analysisSession.analysisContext = analysisContext2;

  return MicroContextObjects(
    declaredVariables: declaredVariables,
    synchronousSession: synchronousSession,
    analysisSession: analysisSession,
    analysisContext: analysisContext,
    analysisContext2: analysisContext2,
  );
}

class MicroContextObjects {
  final DeclaredVariables declaredVariables;
  final SynchronousSession synchronousSession;
  final _MicroAnalysisSessionImpl analysisSession;
  final AnalysisContextImpl analysisContext;
  final _MicroAnalysisContextImpl analysisContext2;

  MicroContextObjects({
    required this.declaredVariables,
    required this.synchronousSession,
    required this.analysisSession,
    required this.analysisContext,
    required this.analysisContext2,
  });

  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    synchronousSession.analysisOptions = analysisOptions;
  }

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
  final SynchronousSession synchronousSession;

  final ResourceProvider resourceProvider;

  @override
  final ContextRoot contextRoot;

  @override
  late _MicroAnalysisSessionImpl currentSession;

  final DeclaredVariables declaredVariables;

  final SourceFactory sourceFactory;

  _MicroAnalysisContextImpl(
    this.fileResolver,
    this.synchronousSession,
    this.contextRoot,
    this.declaredVariables,
    this.sourceFactory,
    this.resourceProvider,
  );

  @override
  AnalysisOptionsImpl get analysisOptions {
    return synchronousSession.analysisOptions;
  }

  @override
  Folder? get sdkRoot => null;

  @Deprecated('Use contextRoot.workspace instead')
  @override
  Workspace get workspace {
    return contextRoot.workspace;
  }

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
    var element = analysisContext.fileResolver.getLibraryByUri(uriStr: uriStr);
    return LibraryElementResultImpl(element);
  }

  @override
  Future<SomeResolvedLibraryResult> getResolvedLibrary(String path) async {
    return analysisContext.fileResolver.resolveLibrary(path: path);
  }

  @override
  Future<SomeResolvedUnitResult> getResolvedUnit(String path) async {
    return analysisContext.fileResolver.resolve(path: path);
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
