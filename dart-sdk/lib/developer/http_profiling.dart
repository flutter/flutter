// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

// package:http_profile adds HTTP profiling information to this list by using
// the [addHttpClientProfilingData] API below.
List<Map<String, dynamic>> _developerProfilingData = <Map<String, dynamic>>[];

/// Records the data associated with an HTTP request for profiling purposes.
///
/// This function should never be called directly. Instead, use
/// [package:http_profile](https://pub.dev/packages/http_profile).
@Since('3.4')
void addHttpClientProfilingData(Map<String, dynamic> requestProfile) {
  _developerProfilingData.add(requestProfile);
  requestProfile['id'] = 'from_package/${_developerProfilingData.length}';
}

/// Returns the data added through [addHttpClientProfilingData].
///
/// This function is only meant for use by networking profilers and the format
/// of the returned data may change over time.
@Since('3.4')
List<Map<String, dynamic>> getHttpClientProfilingData() {
  return UnmodifiableListView(_developerProfilingData);
}
