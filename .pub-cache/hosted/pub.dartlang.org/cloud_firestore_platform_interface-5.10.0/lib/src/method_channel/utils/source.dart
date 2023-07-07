// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/src/aggregate_source.dart';
import 'package:cloud_firestore_platform_interface/src/source.dart';

/// Converts [Source] to [String]
String getSourceString(Source source) {
  switch (source) {
    case Source.server:
      return 'server';
    case Source.cache:
      return 'cache';
    default:
      return 'default';
  }
}

/// Converts [AggregateSource] to [String]
String getAggregateSourceString(AggregateSource source) {
  switch (source) {
    case AggregateSource.server:
      return 'server';
  }
}
