// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'regular_window_content.dart';
import 'window_settings_dialog.dart';
import 'models.dart';
import 'regular_window_edit_dialog.dart';
import 'dialog_window_edit_dialog.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Window Reference App')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: _WindowsTable(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: _WindowCreatorCard())],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowsTable extends StatelessWidget {
  List<DataRow> _buildRows(WindowManager windowManager, BuildContext context) {
    List<DataRow> rows = [];
    for (KeyedWindow controller in windowManager.windows) {
      rows.add(
        DataRow(
          key: controller.key,
          color: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary.withAlpha(20);
            }
            return Colors.transparent;
          }),
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
        ),
      );
    }

    return rows;
  }

  void _showWindowEditDialog(KeyedWindow controller, BuildContext context) {
    return switch (controller.controller) {
      final RegularWindowController regular => showRegularWindowEditDialog(
        context: context,
        controller: regular,
      ),
      final DialogWindowController dialog => showDialogWindowEditDialog(
        context: context,
        controller: dialog,
      ),
      TooltipWindowController() => null,
    };
  }

  static String _getWindowTypeName(BaseWindowController controller) {
    return switch (controller) {
      RegularWindowController() => 'Regular',
      DialogWindowController() => 'Dialog',
      TooltipWindowController() => 'Tooltip',
    };
  }

  @override
  Widget build(BuildContext context) {
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    return DataTable(
      showBottomBorder: true,
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
        DataColumn(label: SizedBox(width: 20, child: Text('')), numeric: true),
      ],
      rows: _buildRows(windowManager, context),
    );
  }
}

class _WindowCreatorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
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
                    windowManager.add(
                      KeyedWindow(
                        key: key,
                        controller: RegularWindowController(
                          delegate: CallbackRegularWindowControllerDelegate(
                            onDestroyed: () => windowManager.remove(key),
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
                OutlinedButton(
                  onPressed: () async {
                    final UniqueKey key = UniqueKey();
                    windowManager.add(
                      KeyedWindow(
                        key: key,
                        controller: DialogWindowController(
                          delegate: CallbackDialogWindowControllerDelegate(
                            onDestroyed: () => windowManager.remove(key),
                          ),
                          title: 'Modeless Dialog',
                          preferredSize: windowSettings.dialogSize,
                        ),
                      ),
                    );
                  },
                  child: const Text('Modeless Dialog'),
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
