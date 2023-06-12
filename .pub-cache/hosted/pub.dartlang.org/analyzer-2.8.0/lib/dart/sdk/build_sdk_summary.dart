// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Build summary for SDK at the given [sdkPath].
///
/// If [embedderYamlPath] is provided, then libraries from this file are
/// appended to the libraries of the specified SDK.
Uint8List buildSdkSummary({
  required ResourceProvider resourceProvider,
  required String sdkPath,
  String? embedderYamlPath,
}) {
  var sdk = FolderBasedDartSdk(
    resourceProvider,
    resourceProvider.getFolder(sdkPath),
  );

  // Append libraries from the embedder.
  if (embedderYamlPath != null) {
    var file = resourceProvider.getFile(embedderYamlPath);
    var content = file.readAsStringSync();
    var map = loadYaml(content) as YamlMap;
    var embedderSdk = EmbedderSdk(
      resourceProvider,
      {file.parent2: map},
      languageVersion: sdk.languageVersion,
    );
    for (var library in embedderSdk.sdkLibraries) {
      var uriStr = library.shortName;
      if (sdk.libraryMap.getLibrary(uriStr) == null) {
        sdk.libraryMap.setLibrary(uriStr, library);
      }
    }
  }

  var librarySources = sdk.sdkLibraries.map((e) {
    return sdk.mapDartUri(e.shortName)!;
  }).toList();

  var analysisContext = AnalysisContextImpl(
    SynchronousSession(AnalysisOptionsImpl(), DeclaredVariables()),
    SourceFactory([DartUriResolver(sdk)]),
  );

  return _Builder(
    analysisContext,
    sdk.allowedExperimentsJson,
    sdk.languageVersion,
    librarySources,
  ).build();
}

class _Builder {
  final AnalysisContextImpl context;
  final String allowedExperimentsJson;
  final Iterable<Source> librarySources;

  final Set<String> libraryUris = <String>{};
  final List<LinkInputLibrary> inputLibraries = [];

  late final AllowedExperiments allowedExperiments;
  Version languageVersion;

  _Builder(
    this.context,
    this.allowedExperimentsJson,
    this.languageVersion,
    this.librarySources,
  ) {
    allowedExperiments = parseAllowedExperiments(allowedExperimentsJson);
  }

  /// Build the linked bundle and return its bytes.
  Uint8List build() {
    librarySources.forEach(_addLibrary);

    var elementFactory = LinkedElementFactory(
      context,
      AnalysisSessionImpl(
        _FakeAnalysisDriver(),
      ),
      Reference.root(),
    );

    var linkResult = link(elementFactory, inputLibraries);

    var bundleBuilder = PackageBundleBuilder();
    for (var library in inputLibraries) {
      bundleBuilder.addLibrary(
        library.uriStr,
        library.units.map((e) => e.uriStr).toList(),
      );
    }
    return bundleBuilder.finish(
      resolutionBytes: linkResult.resolutionBytes,
      sdk: PackageBundleSdk(
        languageVersionMajor: languageVersion.major,
        languageVersionMinor: languageVersion.minor,
        allowedExperimentsJson: allowedExperimentsJson,
      ),
    );
  }

  void _addLibrary(Source source) {
    String uriStr = source.uri.toString();
    if (!libraryUris.add(uriStr)) {
      return;
    }

    var inputUnits = <LinkInputUnit>[];

    CompilationUnit definingUnit = _parse(source);
    inputUnits.add(
      LinkInputUnit(
        partDirectiveIndex: null,
        source: source,
        isSynthetic: false,
        unit: definingUnit,
      ),
    );

    var partDirectiveIndex = 0;
    for (Directive directive in definingUnit.directives) {
      if (directive is NamespaceDirective) {
        String libUri = directive.uri.stringValue!;
        Source libSource = context.sourceFactory.resolveUri(source, libUri)!;
        _addLibrary(libSource);
      } else if (directive is PartDirective) {
        String partUri = directive.uri.stringValue!;
        Source partSource = context.sourceFactory.resolveUri(source, partUri)!;
        CompilationUnit partUnit = _parse(partSource);
        inputUnits.add(
          LinkInputUnit(
            partUriStr: partUri,
            partDirectiveIndex: partDirectiveIndex++,
            source: partSource,
            isSynthetic: false,
            unit: partUnit,
          ),
        );
      }
    }

    inputLibraries.add(
      LinkInputLibrary(
        source: source,
        units: inputUnits,
      ),
    );
  }

  /// Return the [FeatureSet] for the given [uri], must be a `dart:` URI.
  FeatureSet _featureSet(Uri uri) {
    if (uri.isScheme('dart')) {
      var pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        var libraryName = pathSegments.first;
        var experiments = allowedExperiments.forSdkLibrary(libraryName);
        return FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: languageVersion,
          flags: experiments,
        );
      }
    }
    throw StateError('Expected a valid dart: URI: $uri');
  }

  String _getContent(Source source) {
    var uriStr = '${source.uri}';
    var content = source.contents.data;

    // https://github.com/google/json_serializable.dart/issues/692
    // SDK 2.9 was released with the syntax that we later decided to remove.
    // But the current analyzer still says that it supports SDK 2.9, so we
    // have to be able to handle this code. We do this by rewriting it into
    // the syntax that we support now.
    if (uriStr == 'dart:core/uri.dart') {
      return content.replaceAll(
        'String? charsetName = parameters?.["charset"];',
        'String? charsetName = parameters? ["charset"];',
      );
    }
    if (uriStr == 'dart:_http/http_headers.dart') {
      return content.replaceAll(
        'return _originalHeaderNames?.[name] ?? name;',
        'return _originalHeaderNames? [name] ?? name;',
      );
    }

    return content;
  }

  CompilationUnit _parse(Source source) {
    var result = parseString(
      content: _getContent(source),
      featureSet: _featureSet(source.uri),
      throwIfDiagnostics: false,
      path: source.fullName,
    );

    if (result.errors.isNotEmpty) {
      var errorsStr = result.errors.map((e) {
        var location = result.lineInfo.getLocation(e.offset);
        return '${source.fullName}:$location - ${e.message}';
      }).join('\n');
      throw StateError(
        'Unexpected diagnostics:\n$errorsStr',
      );
    }

    var unit = result.unit as CompilationUnitImpl;
    unit.languageVersion = LibraryLanguageVersion(
      package: languageVersion,
      override: null,
    );

    return result.unit;
  }
}

class _FakeAnalysisDriver implements AnalysisDriver {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
