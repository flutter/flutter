// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:fixnum/fixnum.dart' show Int64;
import 'schedule_presubmits/build_bucket_client.dart';

Future<void> main() async {
  final BuildBucketClient client = BuildBucketClient(
    accessTokenService: null,
  );
  final bbv2.Build build = await client
      .getBuild(bbv2.GetBuildRequest(id: Int64(8747021908827058161)));
  print('got response');
  print(build);
  client.close();
}
