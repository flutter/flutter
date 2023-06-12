// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import '../generate/performance_tracker.dart';

class PerformanceTrackingResolvers implements Resolvers {
  final Resolvers _delegate;
  final BuilderActionTracker _tracker;

  PerformanceTrackingResolvers(this._delegate, this._tracker);

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) =>
      _tracker.trackStage('ResolverGet', () => _delegate.get(buildStep));

  @override
  void reset() => _delegate.reset();
}
