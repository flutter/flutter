// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'window_content.dart';

import 'regular_window_content.dart';
import 'window_settings_dialog.dart';
import 'models.dart';
import 'regular_window_edit_dialog.dart';

class MainWindow extends StatelessWidget {
  MainWindow({super.key, required BaseWindowController mainController}) {
    windowManager.add(
      KeyedWindow(
        isMainWindow: true,
        key: UniqueKey(),
        controller: mainController,
      ),
    );
  }

  final WindowManager windowManager = WindowManager();
  final WindowSettings settings = WindowSettings();

  @override
  Widget build(BuildContext context) {
    return WindowManagerAccessor(
      windowManager: windowManager,
      child: WindowSettingsAccessor(
        windowSettings: settings,
        child: ViewAnchor(
          view: ListenableBuilder(
            listenable: windowManager,
            builder: (BuildContext context, Widget? _) {
              final List<Widget> childViews = <Widget>[];
              for (final KeyedWindow window in windowManager.windows) {
                if (window.parent == null && !window.isMainWindow) {
                  childViews.add(
                    WindowContent(
                      controller: window.controller,
                      windowKey: window.key,
                      onDestroyed: () => windowManager.remove(window.key),
                      onError: () => windowManager.remove(window.key),
                    ),
                  );
                }
              }

              return ViewCollection(views: childViews);
            },
          ),
          child: Scaffold(
            appBar: AppBar(title: const Text('Multi Window Reference App')),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 60,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _WindowsTable(windowManager: windowManager),
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListenableBuilder(
                        listenable: windowManager,
                        builder: (BuildContext context, Widget? child) {
                          return _WindowCreatorCard(
                            selectedWindow: windowManager.selected,
                            windowManagerModel: windowManager,
                            windowSettings: settings,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsTable extends StatelessWidget {
  const _WindowsTable({required this.windowManager});

  final WindowManager windowManager;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: windowManager,
      builder: (BuildContext context, Widget? widget) {
        return DataTable(
          showBottomBorder: true,
          onSelectAll: (selected) {
            windowManager.select(null);
          },
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 20,
                child: Text('ID', style: TextStyle(fontSize: 16)),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text('Type', style: TextStyle(fontSize: 16)),
              ),
            ),
            DataColumn(
              label: SizedBox(width: 20, child: Text('')),
              numeric: true,
            ),
          ],
          rows: <DataRow>[
            for (KeyedWindow controller in windowManager.windows)
              _rowForKeyedController(controller, context),
          ],
        );
      },
    );
  }

  DataRow _rowForKeyedController(KeyedWindow controller, BuildContext context) {
    return DataRow(
      key: controller.key,
      color: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).colorScheme.primary.withAlpha(20);
        }
        return Colors.transparent;
      }),
      selected: controller.controller == windowManager.selected,
      onSelectChanged: (bool? selected) {
        if (selected != null) {
          windowManager.select(
            selected ? controller.controller.rootView.viewId : null,
          );
        }
      },
      cells: [
        DataCell(Text('${controller.controller.rootView.viewId}')),
        DataCell(Text(_getWindowTypeName(controller.controller))),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showWindowEditDialog(controller, context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                onPressed: () async {
                  controller.controller.destroy();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWindowEditDialog(KeyedWindow controller, BuildContext context) {
    return switch (controller.controller) {
      final RegularWindowController regular => showRegularWindowEditDialog(
        context: context,
        controller: regular,
      ),
    };
  }

  static String _getWindowTypeName(BaseWindowController controller) {
    return switch (controller) {
      RegularWindowController() => 'Regular',
    };
  }
}

class _WindowCreatorCard extends StatelessWidget {
  const _WindowCreatorCard({
    required this.selectedWindow,
    required this.windowManagerModel,
    required this.windowSettings,
  });

  final BaseWindowController? selectedWindow;
  final WindowManager windowManagerModel;
  final WindowSettings windowSettings;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Text(
                'New Window',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final UniqueKey key = UniqueKey();
                    windowManagerModel.add(
                      KeyedWindow(
                        key: key,
                        controller: RegularWindowController(
                          delegate: CallbackRegularWindowControllerDelegate(
                            onDestroyed: () => windowManagerModel.remove(key),
                          ),
                          title: 'Regular',
                          preferredSize: windowSettings.regularSize,
                        ),
                      ),
                    );
                  },
                  child: const Text('Regular'),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    child: const Text('SETTINGS'),
                    onPressed: () {
                      showWindowSettingsDialog(context, windowSettings);
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
