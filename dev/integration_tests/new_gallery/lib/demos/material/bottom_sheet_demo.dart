// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/demos/material/material_demo_types.dart';

class BottomSheetDemo extends StatelessWidget {
  const BottomSheetDemo({
    super.key,
    required this.type,
  });

  final BottomSheetDemoType type;

  String _title(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    switch (type) {
      case BottomSheetDemoType.persistent:
        return localizations.demoBottomSheetPersistentTitle;
      case BottomSheetDemoType.modal:
        return localizations.demoBottomSheetModalTitle;
    }
  }

  Widget _bottomSheetDemo(BuildContext context) {
    switch (type) {
      case BottomSheetDemoType.persistent:
        return _PersistentBottomSheetDemo();
      case BottomSheetDemoType.modal:
      default:
        return _ModalBottomSheetDemo();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the demo in a [Navigator] to make sure that the modal bottom
    // sheets gets dismissed when changing demo.
    return Navigator(
      // Adding [ValueKey] to make sure that the widget gets rebuilt when
      // changing type.
      key: ValueKey(type),
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(_title(context)),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.add,
                semanticLabel:
                    GalleryLocalizations.of(context)!.demoBottomSheetAddLabel,
              ),
            ),
            body: _bottomSheetDemo(context),
          ),
        );
      },
    );
  }
}

// BEGIN bottomSheetDemoModal#1 bottomSheetDemoPersistent#1

class _BottomSheetContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Center(
              child: Text(
                localizations.demoBottomSheetHeader,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: ListView.builder(
              itemCount: 21,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(localizations.demoBottomSheetItem(index)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// END bottomSheetDemoModal#1 bottomSheetDemoPersistent#1

// BEGIN bottomSheetDemoModal#2

class _ModalBottomSheetDemo extends StatelessWidget {
  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return _BottomSheetContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showModalBottomSheet(context);
        },
        child:
            Text(GalleryLocalizations.of(context)!.demoBottomSheetButtonText),
      ),
    );
  }
}

// END

// BEGIN bottomSheetDemoPersistent#2

class _PersistentBottomSheetDemo extends StatefulWidget {
  @override
  _PersistentBottomSheetDemoState createState() =>
      _PersistentBottomSheetDemoState();
}

class _PersistentBottomSheetDemoState
    extends State<_PersistentBottomSheetDemo> {
  VoidCallback? _showBottomSheetCallback;

  @override
  void initState() {
    super.initState();
    _showBottomSheetCallback = _showPersistentBottomSheet;
  }

  void _showPersistentBottomSheet() {
    setState(() {
      // Disable the show bottom sheet button.
      _showBottomSheetCallback = null;
    });

    Scaffold.of(context)
        .showBottomSheet(
          (context) {
            return _BottomSheetContent();
          },
          elevation: 25,
        )
        .closed
        .whenComplete(() {
          if (mounted) {
            setState(() {
              // Re-enable the bottom sheet button.
              _showBottomSheetCallback = _showPersistentBottomSheet;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _showBottomSheetCallback,
        child:
            Text(GalleryLocalizations.of(context)!.demoBottomSheetButtonText),
      ),
    );
  }
}

// END
