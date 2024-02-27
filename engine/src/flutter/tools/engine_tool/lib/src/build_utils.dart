// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';

import 'environment.dart';

/// A function that returns true or false when given a [BuilderConfig] and its
/// name.
typedef ConfigFilter = bool Function(String name, BuilderConfig config);

/// A function that returns true or false when given a [BuilderConfig] name
/// and a [Build].
typedef BuildFilter = bool Function(String configName, Build build);

/// Returns a filtered copy of [input] filtering out configs where test
/// returns false.
Map<String, BuilderConfig> filterBuilderConfigs(
    Map<String, BuilderConfig> input, ConfigFilter test) {
  return <String, BuilderConfig>{
    for (final MapEntry<String, BuilderConfig> entry in input.entries)
      if (test(entry.key, entry.value)) entry.key: entry.value,
  };
}

/// Returns a copy of [input] filtering out configs that are not runnable
/// on the current platform.
Map<String, BuilderConfig> runnableBuilderConfigs(
    Environment env, Map<String, BuilderConfig> input) {
  return filterBuilderConfigs(input, (String name, BuilderConfig config) {
    return config.canRunOn(env.platform);
  });
}

/// Returns a List of [Build] that match test.
List<Build> filterBuilds(Map<String, BuilderConfig> input, BuildFilter test) {
  return <Build>[
    for (final MapEntry<String, BuilderConfig> entry in input.entries)
      for (final Build build in entry.value.builds)
        if (test(entry.key, build)) build,
  ];
}

/// Returns a list of runnable builds.
List<Build> runnableBuilds(Environment env, Map<String, BuilderConfig> input) {
  return filterBuilds(input, (String configName, Build build) {
    return build.canRunOn(env.platform);
  });
}
