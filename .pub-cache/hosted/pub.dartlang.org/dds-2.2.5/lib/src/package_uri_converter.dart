// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'dds_impl.dart';

/// Converts from `package:` URIs to resolved file paths.
class PackageUriConverter {
  PackageUriConverter(this.dds);

  Future<Map<String, dynamic>> convert(json_rpc.Parameters parameters) async {
    final isolateId = parameters['isolateId'].asString;
    final uris = parameters['uris'].asList;
    final useLocalResolver = parameters['local'].asBoolOr(false);

    final params = <String, dynamic>{
      'isolateId': isolateId,
      'uris': uris,
    };
    final result = await dds.vmServiceClient.sendRequest(
      'lookupResolvedPackageUris',
      params,
    );

    final converter = dds.uriConverter;
    if (converter != null && useLocalResolver) {
      final vmUris = result['uris'];

      final localUris = uris.map((x) => converter(x as String)).toList();

      final resultUris = <String?>[
        for (var i = 0; i < vmUris.length; i++) localUris[i] ?? vmUris[i],
      ];

      return <String, dynamic>{
        'type': 'UriList',
        'uris': resultUris,
      };
    }
    return result;
  }

  final DartDevelopmentServiceImpl dds;
}
