// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN cupertinoScrollbarDemo

class CupertinoScrollbarDemo extends StatelessWidget {
  const CupertinoScrollbarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: Text(localizations.demoCupertinoScrollbarTitle),
      ),
      child: CupertinoScrollbar(
        thickness: 6.0,
        thicknessWhileDragging: 10.0,
        radius: const Radius.circular(34.0),
        radiusWhileDragging: Radius.zero,
        child: ListView.builder(
          itemCount: 120,
          itemBuilder: (context, index) {
            return Center(
              child: Text('item $index',
                  style: CupertinoTheme.of(context).textTheme.textStyle),
            );
          },
        ),
      ),
    );
  }
}

// END
