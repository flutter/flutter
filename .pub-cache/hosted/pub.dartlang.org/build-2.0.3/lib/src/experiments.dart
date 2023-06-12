// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

const Symbol _enabledExperimentsKey = #dartLanguageEnabledExperiments;

/// The list of enabled Dart language experiments for the current [Zone].
///
/// This can be overridden for a new [Zone] by using [withEnabledExperiments].
List<String> get enabledExperiments =>
    Zone.current[_enabledExperimentsKey] as List<String>? ?? const [];

/// Runs [fn] in a [Zone], setting [enabledExperiments] for all code running
/// in that [Zone].
T withEnabledExperiments<T>(T Function() fn, List<String> enabledExperiments) =>
    runZoned(fn, zoneValues: {_enabledExperimentsKey: enabledExperiments});
