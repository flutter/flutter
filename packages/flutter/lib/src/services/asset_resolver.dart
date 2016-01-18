// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'asset_bundle.dart';

/// Base class for resolver components that transform an input into part of
/// a resolved asset's key.
abstract class Qualifier {
  String resolve();
}

/// Qualifier that knows how to find the nearest match among a list of
/// candidates, based on a list of the normative values for each candidate.
///
/// Breakpoints and resolutions should be provided in ascending order. The
/// resolution is done via linear search based on the assumption that the list
/// of candidates is short.
class BreakpointQualifier extends Qualifier {
  BreakpointQualifier({ this.candidates, this.values, this.value }) {
    assert(this.candidates.length == this.values.length);
    assert(this.candidates.length > 0);
  }
  final List<String> candidates;
  final List<double> values;
  double value;
  String resolve() {
    for (int i = 0; i < candidates.length-1; i++) {
      double mid = (values[i] + values[i+1])/2;
      if (value <= mid)
        return candidates[i];
    }
    return candidates.last;
  }
}

/// Base class for asset resolvers.
abstract class AssetResolver {
  /// Return a resolved asset key for the asset named [name].
  Future<String> resolve(String name);
}

/// Base class for resolvers that fetch metadata from the asset bundle as an
/// aid to resolution.
abstract class MetadataAssetResolver extends AssetResolver {
  MetadataAssetResolver({ this.bundle });
  AssetBundle bundle;
  Map<String, String> _metadataCache = new Map<String, String>();

  Future<String> resolve(String name) async {
    if (_metadataCache.containsKey(name)) {
      return resolveFromMetadata(_metadataCache[name]);
    } else {
      Future<String> metadata = bundle.loadString(constructKey(name));
      return _cacheAndResolve(name, await metadata);
    }
  }

  String _cacheAndResolve(String name, String metadata) {
    _metadataCache[name] = metadata;
    return resolveFromMetadata(metadata);
  }

  /// Constructs the asset bundle key for fetching the metadata associated
  /// with the asset with the given key. The default implementation simply
  /// appends ".meta" to the key.
  String constructKey(String name) {
    return name + ".meta";
  }

  String resolveFromMetadata(String metadata);
}

/// Base class for resolvers that use a list of candidate keys as their
/// metadata.
///
/// List entries are newline-separated in the metadata string.
abstract class CandidateAssetResolver extends MetadataAssetResolver {

  CandidateAssetResolver({ AssetBundle bundle }) : super(bundle: bundle);

  String resolveFromMetadata(String metadata) {
    List<String> candidates = metadata.split(new RegExp("\n+"));
    if (candidates.last == '') // allow trailing newlines
      candidates.removeLast();
    return chooseCandidate(candidates);
  }

  String chooseCandidate(List<String> fallbacks);

}
