// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

export '../services/restoration.dart';

class BucketSpy extends StatefulWidget {
  const BucketSpy({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  State<BucketSpy> createState() => BucketSpyState();
}

class BucketSpyState extends State<BucketSpy> {
  RestorationBucket? bucket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bucket = RestorationScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container();
  }
}
