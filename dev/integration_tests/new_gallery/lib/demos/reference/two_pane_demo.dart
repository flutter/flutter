// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/material.dart';
import '../../gallery_localizations.dart';

// BEGIN twoPaneDemo

enum TwoPaneDemoType {
  foldable,
  tablet,
  smallScreen,
}

class TwoPaneDemo extends StatefulWidget {
  const TwoPaneDemo({
    super.key,
    required this.restorationId,
    required this.type,
  });

  final String restorationId;
  final TwoPaneDemoType type;

  @override
  TwoPaneDemoState createState() => TwoPaneDemoState();
}

class TwoPaneDemoState extends State<TwoPaneDemo> with RestorationMixin {
  final RestorableInt _currentIndex = RestorableInt(-1);

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentIndex, 'two_pane_selected_item');
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TwoPanePriority panePriority = TwoPanePriority.both;
    if (widget.type == TwoPaneDemoType.smallScreen) {
      panePriority = _currentIndex.value == -1
          ? TwoPanePriority.start
          : TwoPanePriority.end;
    }
    return SimulateScreen(
      type: widget.type,
      child: TwoPane(
        paneProportion: 0.3,
        panePriority: panePriority,
        startPane: ListPane(
          selectedIndex: _currentIndex.value,
          onSelect: (int index) {
            setState(() {
              _currentIndex.value = index;
            });
          },
        ),
        endPane: DetailsPane(
          selectedIndex: _currentIndex.value,
          onClose: widget.type == TwoPaneDemoType.smallScreen
              ? () {
                  setState(() {
                    _currentIndex.value = -1;
                  });
                }
              : null,
        ),
      ),
    );
  }
}

class ListPane extends StatelessWidget {

  const ListPane({
    super.key,
    required this.onSelect,
    required this.selectedIndex,
  });
  final ValueChanged<int> onSelect;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(GalleryLocalizations.of(context)!.demoTwoPaneList),
      ),
      body: Scrollbar(
        child: ListView(
          restorationId: 'list_demo_list_view',
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            for (int index = 1; index < 21; index++)
              ListTile(
                onTap: () {
                  onSelect(index);
                },
                selected: selectedIndex == index,
                leading: ExcludeSemantics(
                  child: CircleAvatar(child: Text('$index')),
                ),
                title: Text(
                  GalleryLocalizations.of(context)!.demoTwoPaneItem(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DetailsPane extends StatelessWidget {

  const DetailsPane({
    super.key,
    required this.selectedIndex,
    this.onClose,
  });
  final VoidCallback? onClose;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onClose == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        title: Text(
          GalleryLocalizations.of(context)!.demoTwoPaneDetails,
        ),
      ),
      body: ColoredBox(
        color: const Color(0xfffafafa),
        child: Center(
          child: Text(
            selectedIndex == -1
                ? GalleryLocalizations.of(context)!.demoTwoPaneSelectItem
                : GalleryLocalizations.of(context)!
                    .demoTwoPaneItemDetails(selectedIndex),
          ),
        ),
      ),
    );
  }
}

class SimulateScreen extends StatelessWidget {
  const SimulateScreen({
    super.key,
    required this.type,
    required this.child,
  });

  final TwoPaneDemoType type;
  final TwoPane child;

  // An approximation of a real foldable
  static const double foldableAspectRatio = 20 / 18;
  // 16x9 candy bar phone
  static const double singleScreenAspectRatio = 9 / 16;
  // Taller desktop / tablet
  static const double tabletAspectRatio = 4 / 3;
  // How wide should the hinge be, as a proportion of total width
  static const double hingeProportion = 1 / 35;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: AspectRatio(
          aspectRatio: type == TwoPaneDemoType.foldable
              ? foldableAspectRatio
              : type == TwoPaneDemoType.tablet
                  ? tabletAspectRatio
                  : singleScreenAspectRatio,
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = Size(constraints.maxWidth, constraints.maxHeight);
            final Size hingeSize = Size(size.width * hingeProportion, size.height);
            // Position the hinge in the middle of the display
            final Rect hingeBounds = Rect.fromLTWH(
              (size.width - hingeSize.width) / 2,
              0,
              hingeSize.width,
              hingeSize.height,
            );
            return MediaQuery(
              data: MediaQueryData(
                size: size,
                displayFeatures: <DisplayFeature>[
                  if (type == TwoPaneDemoType.foldable)
                    DisplayFeature(
                      bounds: hingeBounds,
                      type: DisplayFeatureType.hinge,
                      state: DisplayFeatureState.postureFlat,
                    ),
                ],
              ),
              child: child,
            );
          }),
        ),
      ),
    );
  }
}

// END
