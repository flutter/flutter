// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/src/method_channel/utils/source.dart';

import 'method_channel_firestore.dart';
import '../../cloud_firestore_platform_interface.dart';

/// An implementation of [AggregateQueryPlatform] for the [MethodChannel]
class MethodChannelAggregateQuery extends AggregateQueryPlatform {
  MethodChannelAggregateQuery(QueryPlatform query) : super(query);

  @override
  Future<AggregateQuerySnapshotPlatform> get({
    required AggregateSource source,
  }) async {
    final Map<String, dynamic>? data = await MethodChannelFirebaseFirestore
        .channel
        .invokeMapMethod<String, dynamic>(
      'AggregateQuery#count',
      <String, dynamic>{
        'query': query,
        'firestore': query.firestore,
        'source': getAggregateSourceString(source),
      },
    );

    return AggregateQuerySnapshotPlatform(
      count: data!['count'] as int,
    );
  }
}
