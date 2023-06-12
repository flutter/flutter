// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
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

  /// Information about packages available in the workspace.
  final Packages packages;

  /// The absolute workspace root path.
  @override
  final String root;

  SimpleWorkspace(this.provider, this.packages, this.root);

  /// TODO(scheglov) Finish switching to [packages].
  Map<String, List<Folder>> get packageMap {
    var packageMap = <String, List<Folder>>{};
    for (var package in packages.packages) {
      packageMap[package.name] = [package.libFolder];
    }
    return packageMap;
  }

  @override
  UriResolver get packageUriResolver =>
      PackageMapUriResolver(provider, packageMap);

  @override
  SourceFactory createSourceFactory(
    DartSdk? sdk,
    SummaryDataStore? summaryData,
  ) {
    List<UriResolver> resolvers = <UriResolver>[];
    if (summaryData != null) {
      resolvers.add(InSummaryUriResolver(summaryData));
    }
    if (sdk != null) {
      resolvers.add(DartUriResolver(sdk));
    }
    resolvers.add(packageUriResolver);
    resolvers.add(ResourceUriResolver(provider));
    return SourceFactory(resolvers);
  }
}
