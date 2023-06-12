// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:math' show min;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';

/// A [ConflictingSummaryException] indicates that two different summaries
/// provided to a [SummaryDataStore] conflict.
class ConflictingSummaryException implements Exception {
  final String duplicatedUri;
  final String summary1Uri;
  final String summary2Uri;
  late final String _message;

  ConflictingSummaryException(Iterable<String> summaryPaths, this.duplicatedUri,
      this.summary1Uri, this.summary2Uri) {
    // Paths are often quite long.  Find and extract out a common prefix to
    // build a more readable error message.
    var prefix = _commonPrefix(summaryPaths.toList());
    _message = '''
These summaries conflict because they overlap:
- ${summary1Uri.substring(prefix)}
- ${summary2Uri.substring(prefix)}
Both contain the file: $duplicatedUri.
This typically indicates an invalid build rule where two or more targets
include the same source.
  ''';
  }

  @override
  String toString() => _message;

  /// Given a set of file paths, find a common prefix.
  int _commonPrefix(List<String> strings) {
    if (strings.isEmpty) return 0;
    var first = strings.first;
    int common = first.length;
    for (int i = 1; i < strings.length; ++i) {
      var current = strings[i];
      common = min(common, current.length);
      for (int j = 0; j < common; ++j) {
        if (first[j] != current[j]) {
          common = j;
          if (common == 0) return 0;
          break;
        }
      }
    }
    // The prefix should end with a file separator.
    var last =
        first.substring(0, common).lastIndexOf(io.Platform.pathSeparator);
    return last < 0 ? 0 : last + 1;
  }
}

/// A placeholder of a source that is part of a package whose analysis results
/// are served from its summary.  This source uses its URI as [fullName] and has
/// empty contents.
class InSummarySource extends BasicSource {
  /// The summary file where this source was defined.
  final String summaryPath;

  final InSummarySourceKind kind;

  InSummarySource({
    required Uri uri,
    required this.summaryPath,
    required this.kind,
  }) : super(uri);

  @override
  TimestampedData<String> get contents => TimestampedData<String>(0, '');

  @override
  bool exists() => true;

  @override
  String toString() => uri.toString();
}

enum InSummarySourceKind { library, part }

/// The [UriResolver] that knows about sources that are served from their
/// summaries.
class InSummaryUriResolver extends UriResolver {
  final SummaryDataStore _dataStore;

  InSummaryUriResolver(this._dataStore);

  @override
  Uri? pathToUri(String path) => null;

  @override
  Source? resolveAbsolute(Uri uri) {
    String uriString = uri.toString();
    String? summaryPath = _dataStore.uriToSummaryPath[uriString];
    if (summaryPath != null) {
      final isLibrary = _dataStore._libraryUris.contains(uriString);
      return InSummarySource(
        uri: uri,
        summaryPath: summaryPath,
        kind:
            isLibrary ? InSummarySourceKind.library : InSummarySourceKind.part,
      );
    }
    return null;
  }
}

/// A [SummaryDataStore] is a container for the data extracted from a set of
/// summary package bundles.  It contains maps which can be used to find linked
/// and unlinked summaries by URI.
class SummaryDataStore {
  /// List of all [PackageBundleReader]s.
  final List<PackageBundleReader> bundles = [];

  /// Map from the URI of a unit to the summary path that contained it.
  final Map<String, String?> uriToSummaryPath = <String, String?>{};

  final Set<String> _libraryUris = <String>{};
  final Set<String> _partUris = <String>{};

  /// Add the given [bundle] loaded from the file with the given [path].
  void addBundle(String? path, PackageBundleReader bundle) {
    bundles.add(bundle);

    for (var library in bundle.libraries) {
      var libraryUri = library.uriStr;
      _libraryUris.add(libraryUri);
      for (var unit in library.units) {
        var unitUri = unit.uriStr;
        uriToSummaryPath[unitUri] = path;
        if (unitUri != libraryUri) {
          _partUris.add(unitUri);
        }
      }
    }
  }

  /// Return `true` if the store contains the linked summary for the library
  /// with the given absolute [uri].
  bool hasLinkedLibrary(String uri) {
    return _libraryUris.contains(uri);
  }

  /// Return `true` if the store contains the unlinked summary for the unit
  /// with the given absolute [uri].
  bool hasUnlinkedUnit(String uri) {
    return uriToSummaryPath.containsKey(uri);
  }

  /// Return `true` if the unit with the [uri] is a part unit in the store.
  bool isPartUnit(String uri) {
    return _partUris.contains(uri);
  }
}
