// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import 'environment.dart';

/// A function that returns true or false when given a [BuildConfig] and its
/// name.
typedef ConfigFilter = bool Function(String name, BuildConfig config);

/// A function that returns true or false when given a [BuildConfig] name
/// and a [GlobalBuild].
typedef BuildFilter = bool Function(String configName, GlobalBuild build);

/// Returns a filtered copy of [input] filtering out configs where test
/// returns false.
Map<String, BuildConfig> filterBuildConfigs(
    Map<String, BuildConfig> input, ConfigFilter test) {
  return <String, BuildConfig>{
    for (final MapEntry<String, BuildConfig> entry in input.entries)
      if (test(entry.key, entry.value)) entry.key: entry.value,
  };
}

/// Returns a copy of [input] filtering out configs that are not runnable
/// on the current platform.
Map<String, BuildConfig> runnableBuildConfigs(
    Environment env, Map<String, BuildConfig> input) {
  return filterBuildConfigs(input, (String name, BuildConfig config) {
    return config.canRunOn(env.platform);
  });
}

/// Returns a List of [GlobalBuild] that match test.
List<GlobalBuild> filterBuilds(
    Map<String, BuildConfig> input, BuildFilter test) {
  return <GlobalBuild>[
    for (final MapEntry<String, BuildConfig> entry in input.entries)
      for (final GlobalBuild build in entry.value.builds)
        if (test(entry.key, build)) build,
  ];
}

/// Returns a list of runnable builds.
List<GlobalBuild> runnableBuilds(
    Environment env, Map<String, BuildConfig> input) {
  return filterBuilds(input, (String configName, GlobalBuild build) {
    return build.canRunOn(env.platform);
  });
}
