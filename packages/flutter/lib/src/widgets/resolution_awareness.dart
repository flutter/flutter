// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection';

import 'package:flutter/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// Asset resolver that knows how to find the asset most closely matching the
/// current device pixel ratio, as given by [MediaQueryData].
///
/// Resolution aware assets are provided in groups. The group name is given
/// as the asset key to the resolver, which then determines which specific
/// asset in the group should be used.
///
/// For each group, a metadata asset should exist keyed by the group name +
/// ".meta". This metadata asset is a textual list of individual assets for
/// that group, separated by newlines. Individual assets should be keyed with a
/// prefix of "Nx/" where N is the nominal device pixel ratio for that asset.
/// N does not need to be an integer.
///
/// For example, suppose an application wants to use a logical icon named
/// "heart". This icon has representations at 1.0, 1.5, and 2.0 pixel ratios. The
/// asset bundle should then contain the following assets:
///
/// heart.meta
/// 1.0x/heart.png
/// 1.5x/heart.png
/// 2.0x/heart.png
///
/// On a device with a 1.0 device pixel ratio, the image chosen would be
/// 1.0x/heart.png; on a device with a 1.3 device pixel ratio, the image chosen
/// would be 1.5x/heart.png.
///
/// Common prefixes will be removed, so the following would be a valid bundle
/// layout for an asset group named "icons/heart":
///
/// icons/heart.meta
/// icons/1.0x/heart.png
/// icons/1.5x/heart.png
/// icons/2.0x/heart.png
class ResolutionAwareAssetResolver extends CandidateAssetResolver {
  ResolutionAwareAssetResolver({ AssetBundle bundle, this.context })
    : super(bundle: bundle);

  BuildContext context;

  SplayTreeMap<double, String> _buildMapping(List<String> candidates) {
    SplayTreeMap<double, String> result = new SplayTreeMap<double, String>();
    RegExp exp = new RegExp(r"/?(\d+(\.\d*)?)x/");
    for (int i = 0; i < candidates.length; i++) {
      Match match = exp.firstMatch(candidates[i]);
      if (match != null && match.groupCount > 0) {
        double resolution = double.parse(match.group(1));
        result[resolution] = candidates[i];
      }
    }
    return result;
  }

  String _resolveFromMapping(BuildContext context, SplayTreeMap<double, String> mapping) {
    MediaQueryData media = MediaQuery.of(context);
    double value = media.devicePixelRatio;
    BreakpointQualifier qualifier = new BreakpointQualifier(
      candidates: mapping.values.toList(),
      values: mapping.keys.toList(),
      value: value
    );
    return qualifier.resolve();
  }

  String chooseCandidate(List<String> candidates) {
    return _resolveFromMapping(context, _buildMapping(candidates));
  }
}

/// Displays an image from an [AssetBundle] using the [ResolutionAwareAssetResolver]
/// resolution strategy.
class ResolutionAwareAssetImage extends AssetImage {
  ResolutionAwareAssetImage({
    Key key,
    String name,
    AssetBundle bundle,
    double width,
    double height,
    ColorFilter colorFilter,
    ImageFit fit,
    FractionalOffset alignment,
    ImageRepeat repeat: ImageRepeat.noRepeat,
    Rect centerSlice
  }) : super(
    key: key,
    name: name,
    bundle: bundle,
    width: width,
    height: height,
    colorFilter: colorFilter,
    fit: fit,
    alignment: alignment,
    repeat: repeat,
    centerSlice: centerSlice
  );

  Widget build(BuildContext context) {
    AssetBundle currentBundle = bundle ?? DefaultAssetBundle.of(context);
    // TODO: Would be nice to be able to cache resolution results, but the
    // bundle could change out from under us at any time...?
    AssetResolver resolver = new ResolutionAwareAssetResolver(
      bundle: currentBundle,
      context: context
    );
    return new RawImageResource(
      image: currentBundle.loadImage(name, resolver),
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice
    );
  }

}
