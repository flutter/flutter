// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/layout/adaptive.dart';

const appBarDesktopHeight = 128.0;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = isDisplayDesktop(context);
    final localizations = GalleryLocalizations.of(context)!;
    final body = SafeArea(
      child: Padding(
        padding: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 72, vertical: 48)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              localizations.starterAppGenericHeadline,
              style: textTheme.displaySmall!.copyWith(
                color: colorScheme.onSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              localizations.starterAppGenericSubtitle,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 48),
            SelectableText(
              localizations.starterAppGenericBody,
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          const ListDrawer(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: const AdaptiveAppBar(
                isDesktop: true,
              ),
              body: body,
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'Extended Add',
                onPressed: () {},
                label: Text(
                  localizations.starterAppGenericButton,
                  style: TextStyle(color: colorScheme.onSecondary),
                ),
                icon: Icon(Icons.add, color: colorScheme.onSecondary),
                tooltip: localizations.starterAppTooltipAdd,
              ),
            ),
          ),
        ],
      );
    } else {
      return Scaffold(
        appBar: const AdaptiveAppBar(),
        body: body,
        drawer: const ListDrawer(),
        floatingActionButton: FloatingActionButton(
          heroTag: 'Add',
          onPressed: () {},
          tooltip: localizations.starterAppTooltipAdd,
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      );
    }
  }
}

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    super.key,
    this.isDesktop = false,
  });

  final bool isDesktop;

  @override
  Size get preferredSize => isDesktop
      ? const Size.fromHeight(appBarDesktopHeight)
      : const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localizations = GalleryLocalizations.of(context)!;
    return AppBar(
      automaticallyImplyLeading: !isDesktop,
      title: isDesktop
          ? null
          : SelectableText(localizations.starterAppGenericTitle),
      bottom: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(26),
              child: Container(
                alignment: AlignmentDirectional.centerStart,
                margin: const EdgeInsetsDirectional.fromSTEB(72, 0, 0, 22),
                child: SelectableText(
                  localizations.starterAppGenericTitle,
                  style: themeData.textTheme.titleLarge!.copyWith(
                    color: themeData.colorScheme.onPrimary,
                  ),
                ),
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: localizations.starterAppTooltipShare,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          tooltip: localizations.starterAppTooltipFavorite,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: localizations.starterAppTooltipSearch,
          onPressed: () {},
        ),
      ],
    );
  }
}

class ListDrawer extends StatefulWidget {
  const ListDrawer({super.key});

  @override
  State<ListDrawer> createState() => _ListDrawerState();
}

class _ListDrawerState extends State<ListDrawer> {
  static const numItems = 9;

  int selectedItem = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = GalleryLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: SelectableText(
                localizations.starterAppTitle,
                style: textTheme.titleLarge,
              ),
              subtitle: SelectableText(
                localizations.starterAppGenericSubtitle,
                style: textTheme.bodyMedium,
              ),
            ),
            const Divider(),
            ...Iterable<int>.generate(numItems).toList().map((i) {
              return ListTile(
                enabled: true,
                selected: i == selectedItem,
                leading: const Icon(Icons.favorite),
                title: Text(
                  localizations.starterAppDrawerItem(i + 1),
                ),
                onTap: () {
                  setState(() {
                    selectedItem = i;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
