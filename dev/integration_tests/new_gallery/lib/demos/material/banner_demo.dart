// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

// BEGIN bannerDemo

enum BannerDemoAction {
  reset,
  showMultipleActions,
  showLeading,
}

class BannerDemo extends StatefulWidget {
  const BannerDemo({super.key});

  @override
  State<BannerDemo> createState() => _BannerDemoState();
}

class _BannerDemoState extends State<BannerDemo> with RestorationMixin {
  static const _itemCount = 20;

  @override
  String get restorationId => 'banner_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_displayBanner, 'display_banner');
    registerForRestoration(_showMultipleActions, 'show_multiple_actions');
    registerForRestoration(_showLeading, 'show_leading');
  }

  final RestorableBool _displayBanner = RestorableBool(true);
  final RestorableBool _showMultipleActions = RestorableBool(true);
  final RestorableBool _showLeading = RestorableBool(true);

  @override
  void dispose() {
    _displayBanner.dispose();
    _showMultipleActions.dispose();
    _showLeading.dispose();
    super.dispose();
  }

  void handleDemoAction(BannerDemoAction action) {
    setState(() {
      switch (action) {
        case BannerDemoAction.reset:
          _displayBanner.value = true;
          _showMultipleActions.value = true;
          _showLeading.value = true;
          break;
        case BannerDemoAction.showMultipleActions:
          _showMultipleActions.value = !_showMultipleActions.value;
          break;
        case BannerDemoAction.showLeading:
          _showLeading.value = !_showLeading.value;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = GalleryLocalizations.of(context)!;
    final banner = MaterialBanner(
      content: Text(localizations.bannerDemoText),
      leading: _showLeading.value
          ? CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.access_alarm, color: colorScheme.onPrimary),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _displayBanner.value = false;
            });
          },
          child: Text(localizations.signIn),
        ),
        if (_showMultipleActions.value)
          TextButton(
            onPressed: () {
              setState(() {
                _displayBanner.value = false;
              });
            },
            child: Text(localizations.dismiss),
          ),
      ],
      backgroundColor: colorScheme.background,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.demoBannerTitle),
        actions: [
          PopupMenuButton<BannerDemoAction>(
            onSelected: handleDemoAction,
            itemBuilder: (context) => <PopupMenuEntry<BannerDemoAction>>[
              PopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.reset,
                child: Text(localizations.bannerDemoResetText),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.showMultipleActions,
                checked: _showMultipleActions.value,
                child: Text(localizations.bannerDemoMultipleText),
              ),
              CheckedPopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.showLeading,
                checked: _showLeading.value,
                child: Text(localizations.bannerDemoLeadingText),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        restorationId: 'banner_demo_list_view',
        itemCount: _displayBanner.value ? _itemCount + 1 : _itemCount,
        itemBuilder: (context, index) {
          if (index == 0 && _displayBanner.value) {
            return banner;
          }
          return ListTile(
            title: Text(
              localizations.starterAppDrawerItem(
                  _displayBanner.value ? index : index + 1),
            ),
          );
        },
      ),
    );
  }
}

// END
