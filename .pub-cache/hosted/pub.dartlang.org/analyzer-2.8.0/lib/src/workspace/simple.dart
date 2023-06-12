// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/workspace/workspace.dart';

/// An abstract class for simple workspaces which do not feature any build
/// artifacts or generated files.
abstract class SimpleWorkspace extends Workspace {
  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final ResourceProvider provider;

  final Map<String, List<Folder>> packageMap;

  /// The absolute workspace root path.
  @override
  final String root;

  SimpleWorkspace(this.provider, this.packageMap, this.root);

  @override
  UriResolver get packageUriResolver =>
      PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    if (summaryData != null) {
      throw UnsupportedError(
          'Summary files are not supported in a Pub workspace.');
    }
    List<UriResolver> resolvers = <UriResolver>[];
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(ResourceUriResolver(provider));
    return SourceFactory(resolvers);
  }
}
