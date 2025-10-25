// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

void main() async {
  ensureAndroidDevice();
  enableFlutterDriverExtension(
    handler: (String? command) async {
      return json.encode(<String, Object?>{
        'supported': await HybridAndroidViewController.checkIfSupported(),
      });
    },
    commands: <CommandExtension>[nativeDriverCommands],
  );

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MainApp());
}

final class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

/// This widget contains the main (top-level) TabBar.
final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two main tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Platform View in a List'),
          // --- Main TabBar ---
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tab 1 (Empty)'),
              Tab(text: 'Tab 2 (Nested)'), // This tab will contain our nested tabs
            ],
          ),
        ),
        // --- Main TabBarView ---
        body: TabBarView(
          children: [
            // --- Main Tab 1 Content ---
            Container(
              alignment: Alignment.center,
              child: const Text('This tab is intentionally empty.'),
            ),

            // --- Main Tab 2 Content ---
            // This is now our new widget that contains the nested tabs.
            const _NestedTabView(),
          ],
        ),
      ),
    );
  }
}

/// This new StatefulWidget holds the nested TabBar and TabBarView.
class _NestedTabView extends StatefulWidget {
  const _NestedTabView();

  @override
  State<_NestedTabView> createState() => _NestedTabViewState();
}

class _NestedTabViewState extends State<_NestedTabView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const String _viewType = 'changing_color_button_platform_view';

  @override
  void initState() {
    super.initState();
    // 2. Initialize the TabController for the nested tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. The layout is a Column containing the nested TabBar and TabBarView
    return Column(
      children: <Widget>[
        // --- Nested TabBar ---
        TabBar(
          controller: _tabController,
          // Use different colors to distinguish from the main TabBar
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const <Widget>[
            Tab(text: 'Button Bar'),
            Tab(text: 'List View'),
          ],
        ),
        // --- Nested TabBarView ---
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // --- Nested Tab 1 Content (Button Bar) ---
              Material(
                elevation: 4.0,
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () { /* Does nothing */ },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                      ElevatedButton(
                        onPressed: () { /* Does nothing */ },
                        child: const Text('Edit'),
                      ),
                      IconButton(
                        onPressed: () { /* Does nothing */ },
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),

              // --- Nested Tab 2 Content (List View) ---
              ListView.builder(
                itemCount: 40,
                itemBuilder: (BuildContext context, int index) {
                  // --- Platform View ---
                  if (index == 10) {
                    return const SizedBox(
                      height: 300,
                      child: _HybridCompositionAndroidPlatformView(
                          viewType: _viewType),
                    );
                  }

                  // --- Dummy Element ---
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('$index'),
                    ),
                    title: Text('Dummy Flutter Widget #$index'),
                    subtitle: const Text('This is a standard list item.'),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// This is the original platform view widget, unchanged.
final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initHybridAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
