// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN appbarDemo

class AppBarDemo extends StatelessWidget {
  const AppBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    var localization = GalleryLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: Text(
          localization.demoAppBarTitle,
        ),
        actions: [
          IconButton(
            tooltip: localization.starterAppTooltipFavorite,
            icon: const Icon(
              Icons.favorite,
            ),
            onPressed: () {},
          ),
          IconButton(
            tooltip: localization.starterAppTooltipSearch,
            icon: const Icon(
              Icons.search,
            ),
            onPressed: () {},
          ),
          PopupMenuButton<Text>(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text(
                    localization.demoNavigationRailFirst,
                  ),
                ),
                PopupMenuItem(
                  child: Text(
                    localization.demoNavigationRailSecond,
                  ),
                ),
                PopupMenuItem(
                  child: Text(
                    localization.demoNavigationRailThird,
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: Center(
        child: Text(
          localization.cupertinoTabBarHomeTab,
        ),
      ),
    );
  }
}

// END
