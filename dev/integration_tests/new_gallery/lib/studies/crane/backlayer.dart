// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract class BackLayerItem extends StatefulWidget {
  final int index;

  const BackLayerItem({super.key, required this.index});
}

class BackLayer extends StatefulWidget {
  final List<BackLayerItem> backLayerItems;
  final TabController tabController;

  const BackLayer({
    super.key,
    required this.backLayerItems,
    required this.tabController,
  });

  @override
  State<BackLayer> createState() => _BackLayerState();
}

class _BackLayerState extends State<BackLayer> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = widget.tabController.index;
    return IndexedStack(
      index: tabIndex,
      children: [
        for (BackLayerItem backLayerItem in widget.backLayerItems)
          ExcludeFocus(
            excluding: backLayerItem.index != tabIndex,
            child: backLayerItem,
          )
      ],
    );
  }
}
