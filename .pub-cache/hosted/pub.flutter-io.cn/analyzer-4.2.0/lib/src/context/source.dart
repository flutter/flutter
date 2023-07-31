// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' as utils;
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/package_build.dart';

/// Return `true` if the given [source] refers to a file that is assumed to be
/// generated.
bool isGeneratedSource(Source? source) {
  if (source == null) {
    return false;
  }
  return file_paths.isGenerated(source.fullName);
}

/// Instances of the class `SourceFactory` resolve possibly relative URI's
/// against an existing [Source].
class SourceFactoryImpl implements SourceFactory {
  /// The resolvers used to resolve absolute URI's.
  final List<UriResolver> resolvers;

  /// Cache of mapping of absolute [Uri]s to [Source]s.
  final HashMap<Uri, Source> _absoluteUriToSourceCache = HashMap<Uri, Source>();

  /// Initialize a newly created source factory with the given absolute URI
  /// [resolvers].
  SourceFactoryImpl(this.resolvers);

  @override
  DartSdk? get dartSdk {
    final resolvers = this.resolvers;
    int length = resolvers.length;
    for (int i = 0; i < length; i++) {
      var resolver = resolvers[i];
      if (resolver is DartUriResolver) {
        return resolver.dartSdk;
      }
    }
    return null;
  }

  @override
  Map<String, List<Folder>>? get packageMap {
    for (var resolver in resolvers) {
      if (resolver is PackageMapUriResolver) {
        return resolver.packageMap;
      }
      if (resolver is PackageBuildPackageUriResolver) {
        return resolver.packageMap;
      }
    }
    return null;
  }

  @override
  Source? forUri(String absoluteUri) {
    try {
      Uri uri;
      try {
        uri = Uri.parse(absoluteUri);
      } catch (exception, stackTrace) {
        AnalysisEngine.instance.instrumentationService
            .logInfo('Could not resolve URI: $absoluteUri $stackTrace');
        return null;
      }
      if (uri.isAbsolute) {
        return _internalResolveUri(null, uri);
      }
    } catch (exception, stackTrace) {
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException(
              "Could not resolve URI: $absoluteUri", exception, stackTrace));
    }
    return null;
  }

  @override
  Source? forUri2(Uri absoluteUri) {
    if (absoluteUri.isAbsolute) {
      try {
        return _internalResolveUri(null, absoluteUri);
      } on AnalysisException catch (exception, stackTrace) {
        // TODO(39284): should this exception be silent?
        AnalysisEngine.instance.instrumentationService.logException(
            SilentException(
                "Could not resolve URI: $absoluteUri", exception, stackTrace));
      }
    }
    return null;
  }

  @override
  Uri? pathToUri(String path) {
    for (var resolver in resolvers) {
      var uri = resolver.pathToUri(path);
      if (uri != null) {
        return uri;
      }
    }
    return null;
  }

  @override
  Source? resolveUri(Source? containingSource, String? containedUri) {
    if (containedUri == null) {
      return null;
    }
    if (containedUri.isEmpty) {
      return containingSource;
    }
    try {
      // Force the creation of an escaped URI to deal with spaces, etc.
      return _internalResolveUri(containingSource, Uri.parse(containedUri));
    } on FormatException {
      return null;
    } catch (exception, stackTrace) {
      String containingFullName =
          containingSource != null ? containingSource.fullName : '<null>';
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService
          .logException(SilentException(
              "Could not resolve URI ($containedUri) "
              "relative to source ($containingFullName)",
              exception,
              stackTrace));
      return null;
    }
  }

  /// Return a source object representing the URI that results from resolving
  /// the given (possibly relative) contained URI against the URI associated
  /// with an existing source object, or `null` if the URI could not be
  /// resolved.
  ///
  /// @param containingSource the source containing the given URI
  /// @param containedUri the (possibly relative) URI to be resolved against the
  ///        containing source
  /// @return the source representing the contained URI
  /// @throws AnalysisException if either the contained URI is invalid or if it
  ///         cannot be resolved against the source object's URI
  Source? _internalResolveUri(Source? containingSource, Uri containedUri) {
    if (!containedUri.isAbsolute) {
      if (containingSource == null) {
        throw AnalysisException(
            "Cannot resolve a relative URI without a containing source: "
            "$containedUri");
      }
      containedUri =
          utils.resolveRelativeUri(containingSource.uri, containedUri);
    }

    var result = _absoluteUriToSourceCache[containedUri];
    if (result == null) {
      for (UriResolver resolver in resolvers) {
        result = resolver.resolveAbsolute(containedUri);
        if (result != null) {
          _absoluteUriToSourceCache[containedUri] = result;
          break;
        }
      }
    }
    return result;
  }
}
