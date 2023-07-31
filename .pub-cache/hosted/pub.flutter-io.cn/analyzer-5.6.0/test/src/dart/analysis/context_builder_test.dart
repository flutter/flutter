// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderImplTest);
  });
}

@reflectiveTest
class ContextBuilderImplTest with ResourceProviderMixin {
  late final ContextBuilderImpl contextBuilder;
  late final ContextRoot contextRoot;

  Folder get sdkRoot => newFolder('/sdk');

  void assertEquals(DeclaredVariables actual, DeclaredVariables expected) {
    Iterable<String> actualNames = actual.variableNames;
    Iterable<String> expectedNames = expected.variableNames;
    expect(actualNames, expectedNames);
    for (String name in expectedNames) {
      expect(actual.get(name), expected.get(name));
    }
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    var folder = newFolder('/home/test');
    contextBuilder = ContextBuilderImpl(resourceProvider: resourceProvider);
    var workspace =
        BasicWorkspace.find(resourceProvider, Packages.empty, folder.path);
    contextRoot = ContextRootImpl(resourceProvider, folder, workspace);
  }

  void test_analysisOptions_invalid() {
    var projectPath = convertPath('/home/test');
    newAnalysisOptionsYamlFile(projectPath, ';');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions = analysisContext.analysisOptionsImpl;
    _expectEqualOptions(analysisOptions, AnalysisOptionsImpl());
  }

  void test_analysisOptions_languageOptions() {
    var projectPath = convertPath('/home/test');
    newAnalysisOptionsYamlFile(
      projectPath,
      AnalysisOptionsFileConfig(
        strictRawTypes: true,
      ).toContent(),
    );

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions = analysisContext.analysisOptionsImpl;
    _expectEqualOptions(
      analysisOptions,
      AnalysisOptionsImpl()..strictRawTypes = true,
    );
  }

  void test_analysisOptions_sdkVersionConstraint_hasPubspec_hasSdk() {
    var projectPath = convertPath('/home/test');
    newPubspecYamlFile(projectPath, '''
environment:
  sdk: ^2.1.0
''');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions = analysisContext.analysisOptionsImpl;
    expect(analysisOptions.sdkVersionConstraint.toString(), '^2.1.0');
  }

  void test_analysisOptions_sdkVersionConstraint_noPubspec() {
    var projectPath = convertPath('/home/test');
    newFile('$projectPath/lib/a.dart', '');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    var analysisOptions = analysisContext.driver.analysisOptions;
    expect(analysisOptions.sdkVersionConstraint, isNull);
  }

  test_createContext_declaredVariables() {
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'foo': 'true'});
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      declaredVariables: declaredVariables,
      sdkPath: sdkRoot.path,
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
  }

  test_createContext_declaredVariables_sdkPath() {
    DeclaredVariables declaredVariables =
        DeclaredVariables.fromMap({'bar': 'true'});
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      declaredVariables: declaredVariables,
      sdkPath: sdkRoot.path,
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    assertEquals(context.driver.declaredVariables, declaredVariables);
    expect(
      context.driver.sourceFactory.dartSdk!.mapDartUri('dart:core')!.fullName,
      sdkRoot.getChildAssumingFile('lib/core/core.dart').path,
    );
  }

  test_createContext_defaults() {
    AnalysisContext context = contextBuilder.createContext(
      contextRoot: contextRoot,
      sdkPath: sdkRoot.path,
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
  }

  test_createContext_sdkPath() {
    var context = contextBuilder.createContext(
      contextRoot: contextRoot,
      sdkPath: sdkRoot.path,
    );
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    expect(
      context.driver.sourceFactory.dartSdk!.mapDartUri('dart:core')!.fullName,
      sdkRoot.getChildAssumingFile('lib/core/core.dart').path,
    );
  }

  test_createContext_sdkRoot() {
    var context = contextBuilder.createContext(
        contextRoot: contextRoot, sdkPath: sdkRoot.path);
    expect(context.analysisOptions, isNotNull);
    expect(context.contextRoot, contextRoot);
    expect(context.sdkRoot, sdkRoot);
  }

  void test_sourceFactory_blazeWorkspace() {
    var projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/${file_paths.blazeWorkspaceMarker}', '');
    newFolder('/workspace/blaze-bin');
    newFolder('/workspace/blaze-genfiles');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    expect(analysisContext.contextRoot.workspace, isA<BlazeWorkspace>());

    expect(
      analysisContext.uriResolvers,
      unorderedEquals([
        isA<DartUriResolver>(),
        isA<BlazePackageUriResolver>(),
        isA<BlazeFileUriResolver>(),
      ]),
    );
  }

  void test_sourceFactory_pubWorkspace() {
    var projectPath = convertPath('/home/my');
    newFile('/home/my/pubspec.yaml', '');

    var analysisContext = _createSingleAnalysisContext(projectPath);
    expect(analysisContext.contextRoot.workspace, isA<PubWorkspace>());

    expect(
      analysisContext.uriResolvers,
      unorderedEquals([
        isA<DartUriResolver>(),
        isA<PackageMapUriResolver>(),
        isA<ResourceUriResolver>(),
      ]),
    );
  }

  /// Return a single expected analysis context at the [path].
  DriverBasedAnalysisContext _createSingleAnalysisContext(String path) {
    var roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(includedPaths: [path]);

    return ContextBuilderImpl(
      resourceProvider: resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: sdkRoot.path,
    );
  }

  static void _expectEqualOptions(
    AnalysisOptionsImpl actual,
    AnalysisOptionsImpl expected,
  ) {
    // TODO(brianwilkerson) Consider moving this to AnalysisOptionsImpl.==.
    expect(actual.enableTiming, expected.enableTiming);
    expect(actual.hint, expected.hint);
    expect(actual.lint, expected.lint);
    expect(
      actual.lintRules.map((l) => l.name),
      unorderedEquals(expected.lintRules.map((l) => l.name)),
    );
    expect(actual.implicitCasts, expected.implicitCasts);
    expect(actual.implicitDynamic, expected.implicitDynamic);
    expect(
        actual.propagateLinterExceptions, expected.propagateLinterExceptions);
    expect(actual.strictInference, expected.strictInference);
    expect(actual.strictRawTypes, expected.strictRawTypes);
  }
}

extension on DriverBasedAnalysisContext {
  AnalysisOptionsImpl get analysisOptionsImpl {
    return driver.analysisOptions as AnalysisOptionsImpl;
  }

  List<UriResolver> get uriResolvers {
    return (driver.sourceFactory as SourceFactoryImpl).resolvers;
  }
}
